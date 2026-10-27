// 【原生冒烟】验证多视图创建、播放替换、共享状态与最终进度。
// 使用正式 runner 与隔离素材，不替代长期真实媒体验收。

import 'package:mochi_player/core/data/tmdb/tmdb_api.dart';
import 'package:mochi_player/features/settings/data/preferences_app_settings_repository.dart';
import 'package:mochi_player/features/settings/data/preferences_theme_repository.dart';
import 'package:mochi_player/features/settings/data/tmdb_settings_runtime.dart';
import 'package:mochi_player/l10n/data/preferences_language_repository.dart';

// 执行方式：fvm flutter run -d macos -t integration_test/windowing_smoke.dart
// 使用正式 runner、真实 media_kit 及沙箱内生成的视频。
// 数据库与偏好均和用户媒体库隔离。
import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
// ignore: always_use_package_imports
import 'video_fixture.dart';
import 'package:flutter/material.dart';
import 'package:mochi_player/app/application/application_exit_coordinator.dart';
import 'package:mochi_player/app/application/main_window_lifecycle.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/playback/playback_target.dart';
import 'package:mochi_player/core/domain/playback/playback_target_resolver.dart';
import 'package:mochi_player/core/data/database/app_database.dart';
import 'package:mochi_player/core/data/database/sqlite_setup.dart';
import 'package:mochi_player/core/platform/desktop_window_service.dart';
import 'package:mochi_player/core/platform/window_service.dart';
import 'package:mochi_player/features/playback/data/database_playback_media_repository.dart';
import 'package:mochi_player/features/playback/application/player_window_coordinator.dart';
import 'package:mochi_player/features/playback/domain/player_window_request.dart';
import 'package:mochi_player/features/playback/data/media_kit_playback_engine.dart';
import 'package:mochi_player/app/bootstrap/player_window_factory.dart';
import 'package:mochi_player/app/bootstrap/mochi_widgets_binding.dart';
import 'package:mochi_player/features/playback/ui/widgets/player_controls.dart';
import 'package:mochi_player/features/settings/application/app_settings_provider.dart';
import 'package:mochi_player/features/settings/application/theme_provider.dart';
import 'package:mochi_player/l10n/application/app_locale_provider.dart';
import 'package:mochi_player/l10n/l10n.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalTarget implements PlaybackTargetResolver {
  @override
  Future<PlaybackTarget> resolve(MediaFile file) async => PlaybackTarget(url: Uri.file(file.path).toString());
}

void check(bool condition, String message) {
  if (!condition) throw StateError(message);
  debugPrint('WINDOWING PASS: $message');
}

Future<void> settle([int milliseconds = 300]) async {
  await Future<void>.delayed(Duration(milliseconds: milliseconds));
  await WidgetsBinding.instance.endOfFrame;
}

void main() async {
  MochiWidgetsBinding();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    exit(1);
  };
  MediaKitPlaybackEngine.initialize();
  SharedPreferences.setMockInitialValues({});
  final directory = await Directory.systemTemp.createTemp('mochi_windowing_smoke_');
  final mediaPath = (await createVideoFixture(directory)).path;
  final sqliteFile = File('${directory.path}/library.sqlite');
  final database = AppDatabase(NativeDatabase(sqliteFile, setup: configureSqlite));
  await database.init();
  await database.saveStorageSource(
    StorageSourceDO(
      sourceId: 'smoke',
      name: 'Smoke source',
      type: 'local',
      endpoint: directory.path,
      rootPath: '/',
      enabled: true,
      username: '',
      password: '',
    ),
  );
  await database.saveScannedFiles([
    MediaFile(
      id: 0,
      sourceId: 'smoke',
      path: mediaPath,
      fileName: 'Smoke video',
      parsedTitle: 'Smoke video',
      addedAt: DateTime.now(),
    ),
  ]);
  final media = (await database.getMediaFile('smoke', mediaPath))!;
  final host = DesktopWindowHost();
  final locales = AppLocaleProvider(repository: PreferencesLanguageRepository());
  await locales.load();
  final settings = AppSettingsProvider(
    settingsRepository: PreferencesAppSettingsRepository(),
    runtime: TmdbSettingsRuntime(tmdbApi: TmdbApi()),
  );
  await settings.load();
  final theme = ThemeProvider(repository: PreferencesThemeRepository());
  final mainWindow = host.create(
    setup: const WindowSetup(size: Size(960, 640), minimumSize: Size(800, 500)),
    builder: (_) => Consumer<AppLocaleProvider>(
      builder: (_, locales, _) => MaterialApp(
        locale: locales.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: Center(child: Text('Single-engine migration smoke test'))),
      ),
    ),
  );
  PlayerWindowSession? playerSession;
  final progressEvents = <int>[];
  final progressSubscription = database.select(database.mediaFiles).watch().listen((files) {
    if (files.isNotEmpty) progressEvents.add(files.single.position);
  });
  final coordinator = PlayerWindowCoordinator(
    createSession: (request) async => playerSession = await createPlayerWindow(
      host: host,
      request: request,
      mediaRepository: DatabasePlaybackMediaRepository(database: database),
      resolver: LocalTarget(),
      engineFactory: MediaKitPlaybackEngine.new,
    ),
  );
  final exiting = ApplicationExitCoordinator(
    beginShutdown: coordinator.beginShutdown,
    closePlayers: coordinator.closeAll,
    cleanUp: () async {
      await locales.drain();
      await progressSubscription.cancel();
      await database.close();
    },
    exitProcess: () {
      unawaited(() async {
        try {
          final reopened = AppDatabase(NativeDatabase(sqliteFile, setup: configureSqlite));
          await reopened.init();
          final saved = (await reopened.getMediaFile('smoke', mediaPath))!;
          check(saved.duration > 0 && saved.position > 0, 'final playback snapshot survives SQLite close/reopen');
          await reopened.close();
          await directory.delete(recursive: true);
          debugPrint('WINDOWING SMOKE COMPLETE');
          exit(0);
        } catch (error, stack) {
          debugPrint('$error\n$stack');
          exit(1);
        }
      }());
    },
    onFailure: (stage, error) {
      debugPrint('$stage: $error');
      exit(1);
    },
  );
  final lifecycle = MainWindowLifecycle(mainWindow, exiting);
  await lifecycle.install();
  runWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: locales),
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: theme),
      ],
      child: host.buildRoot(),
    ),
  );
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => unawaited(() async {
      try {
        final initialViews = WidgetsBinding.instance.platformDispatcher.views.map((v) => v.viewId).toSet();
        PlayerWindowRequest request() => PlayerWindowRequest.fromPlayback(initialMedia: media, queue: [media]);
        await coordinator.openOrReplace(request());
        await settle(1200);
        check(host.windows.length == 2, 'one library and one player window');
        final player = host.windows.singleWhere((w) => w.viewId != mainWindow.viewId);
        check(
          WidgetsBinding.instance.platformDispatcher.views.length == initialViews.length + 1,
          'one additional FlutterView',
        );
        final mainBounds = await mainWindow.getBounds();
        await locales.setLanguage(AppLanguage.en);
        await settle();
        final renderedLocales = <Locale?>[];
        void inspect(Element element) {
          if (element.widget case final MaterialApp app) renderedLocales.add(app.locale);
          element.visitChildren(inspect);
        }

        inspect(WidgetsBinding.instance.rootElement!);
        check(
          renderedLocales.length == 2 && renderedLocales.every((l) => l == const Locale('en')),
          'both views render shared locale',
        );
        await player.setMinimumSize(const Size(420, 260));
        await player.setBounds(const Rect.fromLTWH(100, 100, 480, 300));
        await player.setAlwaysOnTop(true);
        await settle();
        check(await player.isAlwaysOnTop(), 'native always-on-top routes by view ID');
        check((await player.getBounds()).size == const Size(480, 300), 'native mini bounds');
        check(await mainWindow.getBounds() == mainBounds, 'player operations leave library bounds unchanged');
        await player.setAlwaysOnTop(false);
        await player.setFullScreen(true);
        check(await player.isFullScreen(), 'official fullscreen');
        await player.setFullScreen(false);
        check(!await player.isFullScreen(), 'official fullscreen exit');
        await coordinator.openOrReplace(request());
        await settle(1200);
        check(
          host.windows.length == 2 && host.windows.last.viewId == player.viewId,
          'replacement reuses the same player view',
        );
        await playerSession!.close();
        await settle();
        check(
          host.windows.length == 1 && progressEvents.any((position) => position > 0),
          'player close keeps library; shared drift subscription receives progress',
        );
        check(
          (await database.getMediaFile('smoke', mediaPath))!.duration > 0,
          'shared database remains open after player close',
        );
        for (var i = 0; i < 2; i++) {
          await coordinator.openOrReplace(request());
          await settle(1200);
          await playerSession!.close();
          await settle();
          check(host.windows.length == 1, 'reopen/close cycle $i releases player view');
        }
        await coordinator.openOrReplace(request());
        await settle(1200);
        PlayerControls? controls;
        void findControls(Element element) {
          if (element.widget case final PlayerControls candidate) controls = candidate;
          element.visitChildren(findControls);
        }

        findControls(WidgetsBinding.instance.rootElement!);
        check(controls != null, 'production playback controls are mounted');
        controls!.onToggleFullScreen();
        final activePlayer = host.windows.singleWhere((w) => w.viewId != mainWindow.viewId);
        final deadline = DateTime.now().add(const Duration(seconds: 5));
        while (!await activePlayer.isFullScreen()) {
          if (DateTime.now().isAfter(deadline)) throw TimeoutException('Playback controls did not enter fullscreen.');
          await settle(100);
        }
        // 请求标记已一致，此处仅等待 AppKit 动画完成。
        await activePlayer.setFullScreen(true);
        check(await activePlayer.isFullScreen(), 'main close starts with the real player in fullscreen');
        // 验证原生关闭代理所转发的同一个所有者回调。
        lifecycle.onWindowClose();
      } catch (error, stack) {
        debugPrint('$error\n$stack');
        exit(1);
      }
    }()),
  );
}
