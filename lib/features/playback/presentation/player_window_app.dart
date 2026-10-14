import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/playback/playback_target.dart';
import 'package:mochi_player/core/domain/playback/playback_target_resolver.dart';
import 'package:mochi_player/core/platform/desktop_window_service.dart';
import 'package:mochi_player/core/infrastructure/storage/storage_source_playback_resolver.dart';
import 'package:mochi_player/core/platform/window_controls_controller.dart';
import 'package:mochi_player/core/platform/window_service.dart';
import 'package:mochi_player/core/ui/theme/app_theme.dart';
import 'package:mochi_player/core/ui/components/feedback/app_message.dart';
import 'package:mochi_player/features/playback/application/playback_media_store.dart';
import 'package:mochi_player/features/playback/application/player_window_coordinator.dart';
import 'package:mochi_player/features/playback/domain/player_window_request.dart';
import 'package:mochi_player/features/playback/infrastructure/media_kit_playback_engine.dart';
import 'package:mochi_player/features/playback/presentation/controllers/player_window_close_coordinator.dart';
import 'package:mochi_player/features/playback/presentation/pages/player_page.dart';
import 'package:mochi_player/features/settings/application/theme_provider.dart';
import 'package:mochi_player/l10n/app_locale_controller.dart';
import 'package:mochi_player/l10n/l10n.dart';
import 'package:provider/provider.dart';

Future<PlayerWindowSession> createPlayerWindow({
  required DesktopWindowHost host,
  required PlayerWindowRequest request,
  PlaybackMediaStore? mediaStore,
  PlaybackTargetResolver? resolver,
}) async {
  final targetResolver = resolver ?? StorageSourcePlaybackResolver();
  final bootstrap = await _PlayerWindowBootstrap.load(request, mediaStore: mediaStore, resolver: targetResolver);
  final session = _PlayerWindowSessionController(bootstrap);
  final closeCoordinator = PlayerWindowCloseCoordinator();
  final lifecycle = _PlayerWindowLifecycle(
    session: session,
    resolver: targetResolver,
    closeCoordinator: closeCoordinator,
  );
  final windows = host.create(
    setup: const WindowSetup(size: Size(1280, 720), minimumSize: Size(720, 405)),
    builder: (_) => _PlayerWindowApp(
      session: session,
      closeCoordinator: closeCoordinator,
      onCloseRequested: lifecycle.close,
      windowControls: lifecycle.windowControls,
    ),
  );
  lifecycle.windows = windows;
  lifecycle.windowControls = WindowControlsController(viewId: windows.viewId);
  await windows.setPreventClose(true);
  windows.addListener(lifecycle);
  try {
    await WidgetsBinding.instance.endOfFrame;
    await lifecycle.windowControls.positionNativeWindowButtons();
    return lifecycle;
  } catch (_) {
    // A creation that fails after registration still owns a live native view.
    // Retire it before allowing the coordinator to accept another launch.
    await lifecycle.close();
    rethrow;
  }
}

class _PlayerWindowLifecycle with WindowEvents implements PlayerWindowSession {
  _PlayerWindowLifecycle({required this.closeCoordinator, required this.session, required this.resolver});

  late final WindowService windows;
  late final WindowControlsController windowControls;
  final PlayerWindowCloseCoordinator closeCoordinator;
  final _PlayerWindowSessionController session;
  final PlaybackTargetResolver resolver;
  Future<void>? _closing;
  Future<void>? _replacement;

  @override
  bool get isClosing => _closing != null;

  @override
  Future<void> replace(PlayerWindowRequest request) {
    final operation = _replace(request);
    _replacement = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> _replace(PlayerWindowRequest request) async {
    if (isClosing) throw StateError('播放器正在关闭。');
    final next = await _PlayerWindowBootstrap.load(
      request,
      mediaStore: session.bootstrap.mediaStore,
      resolver: resolver,
    );
    if (!next.isReady) throw StateError('播放器无法准备新的媒体请求。');
    if (isClosing) return;
    await closeCoordinator.flushProgress();
    await closeCoordinator.releaseResources();
    if (isClosing) return;
    session.close();
    await WidgetsBinding.instance.endOfFrame;
    if (!isClosing) session.open(next);
    await WidgetsBinding.instance.endOfFrame;
  }

  @override
  Future<void> activate() async {
    if (isClosing) return;
    await windows.activate();
    if (!session.bootstrap.isReady) {
      throw const PlayerWindowLaunchFailed();
    }
  }

  @override
  void onWindowClose() => unawaited(close());

  @override
  Future<void> close() => _closing ??= _close();

  Future<void> _close() async {
    session.beginShutdown();
    await closeCoordinator.prepareClose(
      settleSession: () async {
        await _replacement;
      },
      detachView: () async {
        session.close();
        await WidgetsBinding.instance.endOfFrame;
      },
    );
    windows.removeListener(this);
    try {
      await windows.close();
    } finally {
      windowControls.dispose();
      session.dispose();
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

  void open(_PlayerWindowBootstrap next) {
    if (!_acceptRequests) return;
    _bootstrap = next;
    _isOpen = true;
    notifyListeners();
  }

  void close() {
    if (!_isOpen) return;
    _isOpen = false;
    notifyListeners();
  }
}

enum _PlayerLaunchFailure { load, target }

class _PlayerWindowBootstrap {
  const _PlayerWindowBootstrap._({
    required this.request,
    required this.mediaStore,
    this.failure,
    this.initialMedia,
    this.queue = const [],
    this.initialTarget,
  });

  final PlayerWindowRequest request;
  final PlaybackMediaStore mediaStore;
  final _PlayerLaunchFailure? failure;
  final MediaFile? initialMedia;
  final List<MediaFile> queue;
  final PlaybackTarget? initialTarget;

  bool get isReady => initialMedia != null && initialTarget != null;

  static Future<_PlayerWindowBootstrap> load(
    PlayerWindowRequest request, {
    PlaybackMediaStore? mediaStore,
    required PlaybackTargetResolver resolver,
  }) async {
    final effectiveMediaStore = mediaStore ?? DatabasePlaybackMediaStore();
    try {
      final persistedInitialMedia = await effectiveMediaStore.readMediaFile(
        sourceId: request.initialMedia.sourceId,
        path: request.initialMedia.path,
      );
      final initialMedia = persistedInitialMedia ?? request.initialMedia;
      final queue = (await Future.wait(
        request.queue.map(
          (reference) async =>
              await effectiveMediaStore.readMediaFile(sourceId: reference.sourceId, path: reference.path) ?? reference,
        ),
      )).toList(growable: false);
      final target = await resolver.resolve(initialMedia);
      return _PlayerWindowBootstrap._(
        request: request,
        mediaStore: effectiveMediaStore,
        failure: target == null ? _PlayerLaunchFailure.target : null,
        initialMedia: initialMedia,
        queue: queue,
        initialTarget: target,
      );
    } catch (error) {
      return _PlayerWindowBootstrap._(
        request: request,
        mediaStore: effectiveMediaStore,
        failure: _PlayerLaunchFailure.load,
      );
    }
  }
}

class _PlayerWindowApp extends StatelessWidget {
  const _PlayerWindowApp({
    required this.session,
    required this.closeCoordinator,
    required this.onCloseRequested,
    required this.windowControls,
  });

  final _PlayerWindowSessionController session;
  final PlayerWindowCloseCoordinator closeCoordinator;
  final Future<void> Function() onCloseRequested;
  final WindowControlsController windowControls;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: windowControls),
        ChangeNotifierProvider.value(value: session),
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
            home: AppMessageHost(
              child: Consumer<_PlayerWindowSessionController>(
                builder: (context, session, _) => _PlayerWindowHome(
                  bootstrap: session.bootstrap,
                  isOpen: session.isOpen,
                  isClosing: session.isClosing,
                  closeCoordinator: closeCoordinator,
                  onCloseRequested: onCloseRequested,
                ),
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
                  bootstrap.failure == _PlayerLaunchFailure.load
                      ? context.l10n.playerBootstrapFailed
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
