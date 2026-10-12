import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/playback/playback_target.dart';
import 'package:mochi_player/core/infrastructure/database/database_service.dart';
import 'package:mochi_player/core/infrastructure/storage/storage_source_playback_resolver.dart';
import 'package:mochi_player/core/platform/window_controls_controller.dart';
import 'package:mochi_player/core/platform/window_service.dart';
import 'package:mochi_player/core/ui/theme/app_theme.dart';
import 'package:mochi_player/features/playback/application/playback_media_store.dart';
import 'package:mochi_player/features/playback/application/player_window_coordinator.dart';
import 'package:mochi_player/features/playback/domain/player_window_request.dart';
import 'package:mochi_player/features/playback/infrastructure/media_kit_playback_engine.dart';
import 'package:mochi_player/features/playback/presentation/controllers/player_window_close_coordinator.dart';
import 'package:mochi_player/features/playback/presentation/pages/player_page.dart';
import 'package:mochi_player/features/settings/application/app_settings_provider.dart';
import 'package:mochi_player/features/settings/application/theme_provider.dart';
import 'package:mochi_player/l10n/app_locale_controller.dart';
import 'package:mochi_player/l10n/l10n.dart';
import 'package:provider/provider.dart';

class PlayerWindow {
  static final coordinator = PlayerWindowCoordinator(WindowService.instance);

  static Future<void> openOrReplace(PlayerWindowRequest request) => coordinator.openOrReplace(request);
}

/// Bootstraps only playback dependencies; it never builds the library shell or
/// initializes the app router in the child engine.
Future<void> runPlayerWindow(WindowHandle controller, PlayerWindowRequest request) async {
  await WindowService.instance.initialize();
  final locales = AppLocaleController();
  await locales.load();
  final bootstrap = await _PlayerWindowBootstrap.load(request);
  final session = _PlayerWindowSessionController(bootstrap);
  final closeCoordinator = PlayerWindowCloseCoordinator();
  final lifecycle = _PlayerWindowLifecycle(
    controller: controller,
    locales: locales,
    closeCoordinator: closeCoordinator,
    session: session,
  );
  await WindowService.instance.setPreventClose(true);
  WindowService.instance.addListener(lifecycle);

  await controller.setHandler((call) async {
    if (call.method == 'app.setLocale') {
      locales.applySnapshot(call.arguments);
      return null;
    }
    if (call.method == 'player.ready') {
      await WidgetsBinding.instance.endOfFrame;
      return <String, Object?>{'windowId': controller.id, ...session.readiness()};
    }
    if (call.method == 'player.replaceRequest') {
      final arguments = call.arguments;
      final nextRequest = arguments is String ? PlayerWindowRequest.tryDecode(arguments) : null;
      if (nextRequest == null) {
        throw const FormatException('Invalid player-window request.');
      }
      if (lifecycle.isClosing) return <String, Object?>{'ready': false, 'state': 'closing'};
      final nextBootstrap = await lifecycle.replace(nextRequest);
      return session.readinessFor(nextBootstrap);
    }
    if (call.method == 'player.activate') {
      if (!lifecycle.isClosing) await WindowService.instance.activate();
      return null;
    }
    if (call.method == 'player.prepareClose') return lifecycle.prepareClose();
    if (call.method == 'player.close') {
      // Reply before destroying this engine's method channel.
      Timer(const Duration(milliseconds: 50), () => unawaited(lifecycle.close()));
      return null;
    }
    throw MissingPluginException('Unsupported player-window method: ${call.method}');
  });

  // Read the authority before the first frame; the main also pushes its latest
  // revision after ready, covering a language change during native creation.
  try {
    final all = await WindowService.instance.getAll().timeout(const Duration(seconds: 1));
    for (final candidate in all) {
      if (candidate.id != controller.id && PlayerWindowRequest.tryDecode(candidate.arguments) == null) {
        locales.applySnapshot(await candidate.invoke<Map<Object?, Object?>>('app.getLocale'));
        break;
      }
    }
  } catch (error) {
    debugPrint('Initial player language synchronization failed: $error');
  }

  runApp(
    _PlayerWindowApp(
      locales: locales,
      session: session,
      closeCoordinator: closeCoordinator,
      onCloseRequested: lifecycle.close,
    ),
  );
  unawaited(
    WindowService.instance.configure(
      const WindowSetup(size: Size(1280, 720), minimumSize: Size(720, 405), backgroundColor: Colors.black),
    ),
  );
}

class _PlayerWindowLifecycle with WindowEvents {
  _PlayerWindowLifecycle({
    required this.controller,
    required this.closeCoordinator,
    required this.session,
    required this.locales,
  });

  final WindowHandle controller;
  final AppLocaleController locales;
  final PlayerWindowCloseCoordinator closeCoordinator;
  final _PlayerWindowSessionController session;
  Future<_PlayerWindowBootstrap>? _replacement;
  Future<Map<String, Object?>>? _preparing;
  Future<void>? _closing;

  bool get isClosing => _preparing != null;

  Future<_PlayerWindowBootstrap> replace(PlayerWindowRequest request) {
    return _replacement = session.replace(request);
  }

  @override
  void onWindowClose() => unawaited(close());

  Future<Map<String, Object?>> prepareClose() => _preparing ??= _prepareClose();

  Future<Map<String, Object?>> _prepareClose() {
    locales.beginShutdown();
    session.beginShutdown();
    return closeCoordinator.prepareClose(
      settleSession: () async {
        await _replacement;
      },
      detachView: () async {
        session.close();
        await WidgetsBinding.instance.endOfFrame;
      },
      closeDatabase: () => DatabaseService().close(),
    );
  }

  Future<void> close() => _closing ??= _close();

  Future<void> _close() async {
    await prepareClose();
    try {
      await _notifyMainWindow().timeout(const Duration(seconds: 1));
    } catch (_) {
      debugPrint('播放器关闭通知未送达主窗口。');
    }
    WindowService.instance.removeListener(this);
    await WindowService.instance.close();
  }

  Future<void> _notifyMainWindow() async {
    final changed = session.bootstrap.mediaStore.changedMedia.map((key) => key.toJson()).toList(growable: false);
    for (final candidate in await WindowService.instance.getAll()) {
      if (candidate.id == controller.id || PlayerWindowRequest.tryDecode(candidate.arguments) != null) continue;
      await candidate.invoke<void>('player.closed', {'windowId': controller.id, 'changedMedia': changed});
      return;
    }
  }
}

class _PlayerWindowSessionController extends ChangeNotifier {
  _PlayerWindowSessionController(this._bootstrap);

  _PlayerWindowBootstrap _bootstrap;
  bool _isOpen = true;
  bool _acceptRequests = true;

  void beginShutdown() {
    if (!_acceptRequests) return;
    _acceptRequests = false;
    notifyListeners();
  }

  bool get isClosing => !_acceptRequests;

  _PlayerWindowBootstrap get bootstrap => _bootstrap;

  bool get isOpen => _isOpen;

  Map<String, Object?> readiness() => readinessFor(_bootstrap);

  Map<String, Object?> readinessFor(_PlayerWindowBootstrap bootstrap) => {
    'ready': bootstrap.isReady,
    'state': bootstrap.isReady ? 'ready' : 'failed',
    'requestId': bootstrap.request.requestId,
    'database': bootstrap.databaseStatus,
    'media': bootstrap.mediaStatus,
    'target': bootstrap.targetStatus,
  };

  Future<_PlayerWindowBootstrap> replace(PlayerWindowRequest request) async {
    final next = await _PlayerWindowBootstrap.load(
      request,
      appSettingsProvider: _bootstrap.appSettingsProvider,
      mediaStore: _bootstrap.mediaStore,
      windowControlsController: _bootstrap.windowControlsController,
    );
    if (!next.isReady || !_acceptRequests) return next;
    _bootstrap = next;
    _isOpen = true;
    notifyListeners();
    return next;
  }

  void close() {
    if (!_isOpen) return;
    _isOpen = false;
    notifyListeners();
  }
}

class _PlayerWindowBootstrap {
  const _PlayerWindowBootstrap._({
    required this.request,
    required this.appSettingsProvider,
    required this.mediaStore,
    required this.windowControlsController,
    required this.databaseStatus,
    required this.mediaStatus,
    required this.targetStatus,
    this.initialMedia,
    this.queue = const [],
    this.initialTarget,
  });

  final PlayerWindowRequest request;
  final AppSettingsProvider appSettingsProvider;
  final PlaybackMediaStore mediaStore;
  final WindowControlsController windowControlsController;
  final String databaseStatus;
  final String mediaStatus;
  final String targetStatus;
  final MediaFile? initialMedia;
  final List<MediaFile> queue;
  final PlaybackTarget? initialTarget;

  bool get isReady => initialMedia != null && initialTarget != null;

  static Future<_PlayerWindowBootstrap> load(
    PlayerWindowRequest request, {
    AppSettingsProvider? appSettingsProvider,
    PlaybackMediaStore? mediaStore,
    WindowControlsController? windowControlsController,
  }) async {
    final effectiveAppSettingsProvider = appSettingsProvider ?? AppSettingsProvider();
    final effectiveMediaStore = mediaStore ?? DatabasePlaybackMediaStore();
    final effectiveWindowControlsController = windowControlsController ?? WindowControlsController();
    try {
      await DatabaseService().init();
      if (appSettingsProvider == null) {
        await effectiveAppSettingsProvider.load();
      }

      final persistedInitialMedia = await effectiveMediaStore.readMediaFile(
        sourceId: request.initialMedia.sourceId,
        path: request.initialMedia.path,
      );
      final initialMedia = persistedInitialMedia ?? request.initialMedia.toFallbackMediaFile();
      if (initialMedia == null) {
        return _PlayerWindowBootstrap._(
          request: request,
          appSettingsProvider: effectiveAppSettingsProvider,
          mediaStore: effectiveMediaStore,
          windowControlsController: effectiveWindowControlsController,
          databaseStatus: 'initialized',
          mediaStatus: 'media_missing',
          targetStatus: 'unresolved',
        );
      }
      final queue = (await Future.wait(
        request.queue.map(
          (reference) async =>
              await effectiveMediaStore.readMediaFile(sourceId: reference.sourceId, path: reference.path) ??
              reference.toFallbackMediaFile(),
        ),
      )).whereType<MediaFile>().toList(growable: false);
      final target = await StorageSourcePlaybackResolver().resolve(initialMedia);
      return _PlayerWindowBootstrap._(
        request: request,
        appSettingsProvider: effectiveAppSettingsProvider,
        mediaStore: effectiveMediaStore,
        windowControlsController: effectiveWindowControlsController,
        databaseStatus: 'initialized',
        mediaStatus: persistedInitialMedia == null ? 'loaded_from_request' : 'loaded_from_database',
        targetStatus: target == null ? 'target_failed' : 'resolved',
        initialMedia: initialMedia,
        queue: queue,
        initialTarget: target,
      );
    } catch (error) {
      return _PlayerWindowBootstrap._(
        request: request,
        appSettingsProvider: effectiveAppSettingsProvider,
        mediaStore: effectiveMediaStore,
        windowControlsController: effectiveWindowControlsController,
        databaseStatus: 'bootstrap_failed',
        mediaStatus: 'not_loaded',
        targetStatus: 'unresolved',
      );
    }
  }
}

class _PlayerWindowApp extends StatelessWidget {
  const _PlayerWindowApp({
    required this.locales,
    required this.session,
    required this.closeCoordinator,
    required this.onCloseRequested,
  });

  final _PlayerWindowSessionController session;
  final PlayerWindowCloseCoordinator closeCoordinator;
  final Future<void> Function() onCloseRequested;

  final AppLocaleController locales;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: locales),
        ChangeNotifierProvider.value(value: session.bootstrap.appSettingsProvider),
        ChangeNotifierProvider.value(value: session.bootstrap.windowControlsController),
        ChangeNotifierProvider.value(value: session),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer2<ThemeProvider, AppLocaleController>(
        builder: (context, themeProvider, locales, _) {
          return MaterialApp(
            title: 'Mochi Player',
            locale: locales.locale,
            localeListResolutionCallback: AppLocaleController.resolve,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: AppTheme.lightThemeFor(themeProvider.accentColor.color),
            darkTheme: AppTheme.darkThemeFor(themeProvider.accentColor.color),
            home: Consumer<_PlayerWindowSessionController>(
              builder: (context, session, _) => _PlayerWindowHome(
                bootstrap: session.bootstrap,
                isOpen: session.isOpen,
                isClosing: session.isClosing,
                closeCoordinator: closeCoordinator,
                onCloseRequested: onCloseRequested,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlayerWindowHome extends StatelessWidget {
  const _PlayerWindowHome({
    required this.bootstrap,
    required this.isOpen,
    required this.isClosing,
    required this.closeCoordinator,
    required this.onCloseRequested,
  });

  final _PlayerWindowBootstrap bootstrap;
  final bool isOpen;
  final bool isClosing;
  final PlayerWindowCloseCoordinator closeCoordinator;
  final Future<void> Function() onCloseRequested;

  @override
  Widget build(BuildContext context) {
    return ExcludeFocus(
      excluding: isClosing,
      child: IgnorePointer(
        ignoring: isClosing,
        child: Stack(
          children: [
            Positioned.fill(
              child: !isOpen
                  ? const ColoredBox(color: Colors.black)
                  : bootstrap.isReady
                  ? PlayerPage(
                      key: ValueKey(bootstrap.request.requestId),
                      videoItem: bootstrap.initialMedia!,
                      engineFactory: MediaKitPlaybackEngine.new,
                      target: bootstrap.initialTarget!,
                      contextTitle: bootstrap.request.contextTitle,
                      playlist: bootstrap.queue,
                      mediaStore: bootstrap.mediaStore,
                      regularMinimumWindowSize: const Size(720, 405),
                      closeCoordinator: closeCoordinator,
                    )
                  : _PlayerWindowLaunchFailure(bootstrap: bootstrap, onCloseRequested: onCloseRequested),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerWindowLaunchFailure extends StatelessWidget {
  const _PlayerWindowLaunchFailure({required this.bootstrap, required this.onCloseRequested});

  final _PlayerWindowBootstrap bootstrap;
  final Future<void> Function() onCloseRequested;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 36),
                const SizedBox(height: 16),
                Text(context.l10n.playerUnavailable, style: TextStyle(color: Colors.white, fontSize: 20)),
                const SizedBox(height: 8),
                Text(
                  bootstrap.databaseStatus == 'bootstrap_failed'
                      ? context.l10n.playerBootstrapFailed
                      : bootstrap.initialMedia == null
                      ? context.l10n.playerMediaMissing
                      : context.l10n.playerTargetFailed,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                FilledButton(onPressed: onCloseRequested, child: Text(context.l10n.close)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
