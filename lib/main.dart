// 【启动入口】初始化共享依赖、视图宿主与退出流程，再启动应用界面。
// 应用级资源由启动与退出流程统一管理，页面不自行创建共享服务。

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mochi_player/app/application/application_exit_coordinator.dart';
import 'package:mochi_player/app/application/main_window_lifecycle.dart';
import 'package:mochi_player/app/bootstrap/application_dependencies.dart';
import 'package:mochi_player/app/bootstrap/mochi_widgets_binding.dart';
import 'package:mochi_player/app/bootstrap/player_window_factory.dart';
import 'package:mochi_player/app/routing/app_router.dart';
import 'package:mochi_player/core/data/database/app_database.dart';
import 'package:mochi_player/core/data/storage/local_storage_adapter.dart';
import 'package:mochi_player/core/data/storage/smb_storage_adapter.dart';
import 'package:mochi_player/core/data/storage/webdav_storage_adapter.dart';
import 'package:mochi_player/core/data/tmdb/tmdb_api.dart';
import 'package:mochi_player/core/domain/storage/storage_adapter_registry.dart';
import 'package:mochi_player/core/platform/desktop_window_service.dart';
import 'package:mochi_player/core/platform/window_controls_controller.dart';
import 'package:mochi_player/core/platform/window_service.dart';
import 'package:mochi_player/core/ui/theme/app_theme.dart';
import 'package:mochi_player/features/library/sources/application/storage_sources_service.dart';
import 'package:mochi_player/features/playback/application/player_window_coordinator.dart';
import 'package:mochi_player/features/playback/data/media_kit_playback_engine.dart';
import 'package:mochi_player/features/settings/application/theme_provider.dart';
import 'package:mochi_player/features/settings/data/preferences_app_settings_repository.dart';
import 'package:mochi_player/features/settings/data/preferences_theme_repository.dart';
import 'package:mochi_player/l10n/application/app_locale_provider.dart';
import 'package:mochi_player/l10n/data/preferences_language_repository.dart';
import 'package:mochi_player/l10n/l10n.dart';
import 'package:provider/provider.dart';

void main() async {
  MochiWidgetsBinding();
  MediaKitPlaybackEngine.initialize();
  final host = DesktopWindowHost();

  // 初始化数据库
  final dependencies = ApplicationDependencies(
    database: AppDatabase.open(),
    tmdb: TmdbApi(),
    storageRegistry: StorageAdapterRegistry([LocalStorageAdapter(), WebDavStorageAdapter(), SmbStorageAdapter()]),
    settingsRepository: PreferencesAppSettingsRepository(),
  );
  await dependencies.database.init();

  final locales = AppLocaleProvider(repository: PreferencesLanguageRepository());
  await locales.load();
  final appSettingsProvider = dependencies.settings;
  await appSettingsProvider.load();
  final mediaLibraryProvider = dependencies.mediaLibrary;
  final playerWindows = PlayerWindowCoordinator(
    createSession: (request) => createPlayerWindow(
      host: host,
      request: request,
      mediaRepository: dependencies.playbackRepository,
      resolver: dependencies.playbackResolver,
      engineFactory: MediaKitPlaybackEngine.new,
    ),
  );
  late final WindowControlsController windowControlsController;
  final router = createAppRouter();
  final exiting = ValueNotifier(false);
  const windowSetup = WindowSetup(size: Size(1200, 800), minimumSize: Size(900, 600));
  final windows = host.create(
    setup: windowSetup,
    builder: (_) => ChangeNotifierProvider.value(
      value: windowControlsController,
      child: ValueListenableBuilder<bool>(
        valueListenable: exiting,
        child: MochiPlayerApp(router: router),
        builder: (context, isExiting, child) => ExcludeFocus(
          excluding: isExiting,
          child: IgnorePointer(ignoring: isExiting, child: child),
        ),
      ),
    ),
  );
  windowControlsController = WindowControlsController(viewId: windows.viewId);

  final themeProvider = ThemeProvider(repository: PreferencesThemeRepository());
  final exitCoordinator = ApplicationExitCoordinator(
    beginShutdown: () {
      exiting.value = true;
      locales.beginShutdown();
      playerWindows.beginShutdown();
      mediaLibraryProvider.beginShutdown();
      dependencies.storageSources.beginShutdown();
      dependencies.fileBrowser.beginShutdown();
      appSettingsProvider.beginShutdown();
      themeProvider.beginShutdown();
    },
    closePlayers: playerWindows.closeAll,
    cleanUp: () async {
      await Future.wait([
        mediaLibraryProvider.shutdown(),
        dependencies.storageSources.drain(),
        dependencies.fileBrowser.shutdown(),
        appSettingsProvider.waitForPendingSave(),
        themeProvider.waitForPendingSave(),
        locales.drain(),
      ]);
      await dependencies.database.close();
    },
    exitProcess: windows.exitApplication,
    onFailure: (stage, _) => debugPrint('应用退出阶段失败或超时: $stage'),
  );
  await MainWindowLifecycle(windows, exitCoordinator).install();

  runWidget(
    MultiProvider(
      providers: [
        Provider<PlayerWindowCoordinator>.value(value: playerWindows),
        ChangeNotifierProvider.value(value: locales),
        ChangeNotifierProvider.value(value: appSettingsProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: dependencies.fileBrowser),
        Provider<StorageSourcesService>.value(value: dependencies.storageSources),
        ChangeNotifierProvider.value(value: mediaLibraryProvider),
        ChangeNotifierProvider.value(value: dependencies.trending),
      ],
      child: host.buildRoot(),
    ),
  );
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!exitCoordinator.isExiting) {
      unawaited(windowControlsController.configureTitlebar(minimumSize: windowSetup.minimumSize));
    }
  });
}

class MochiPlayerApp extends StatelessWidget {
  const MochiPlayerApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp.router(
      routerConfig: router,
      title: 'Mochi Player',
      locale: context.watch<AppLocaleProvider>().locale,
      localeListResolutionCallback: AppLocaleProvider.resolve,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      themeAnimationDuration: kThemeAnimationDuration,
      themeAnimationCurve: Curves.linear,

      // 直接使用从 AppTheme 类中导入的主题
      theme: AppTheme.lightThemeFor(themeProvider.accentColor.color),
      darkTheme: AppTheme.darkThemeFor(themeProvider.accentColor.color),
    );
  }
}
