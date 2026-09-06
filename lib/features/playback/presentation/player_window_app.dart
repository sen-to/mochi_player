import 'dart:async';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mochi_player/app/presentation/widgets/windows_window_buttons.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/playback/playback_target.dart';
import 'package:mochi_player/core/infrastructure/database/database_service.dart';
import 'package:mochi_player/core/infrastructure/storage/storage_source_playback_resolver.dart';
import 'package:mochi_player/core/platform/window_controls_controller.dart';
import 'package:mochi_player/core/platform/window_controls_layout.dart';
import 'package:mochi_player/core/ui/theme/app_theme.dart';
import 'package:mochi_player/features/playback/application/playback_media_store.dart';
import 'package:mochi_player/features/playback/domain/player_window_request.dart';
import 'package:mochi_player/features/playback/presentation/controllers/player_window_close_coordinator.dart';
import 'package:mochi_player/features/playback/presentation/pages/player_page.dart';
import 'package:mochi_player/features/settings/application/app_settings_provider.dart';
import 'package:mochi_player/features/settings/application/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

/// Owns the separate Flutter engine used exclusively for video playback.
class PlayerWindow {
  static WindowController? _activeController;
  static Future<void> _launchQueue = Future<void>.value();

  /// Creates a child engine from a durable, protocol-versioned request.
  static Future<WindowController> _open(PlayerWindowRequest request) {
    return WindowController.create(WindowConfiguration(arguments: request.encode(), hiddenAtLaunch: true));
  }

  /// Installs the message sent by the player when it has safely closed.
  static Future<void> installMainWindowHandler(
    WindowController controller, {
    required Future<void> Function(List<PlaybackMediaKey> changedMedia) onPlaybackStateChanged,
  }) {
    return controller.setWindowMethodHandler((call) async {
      if (call.method != 'player.closed') {
        throw MissingPluginException('Unsupported main-window method: ${call.method}');
      }
      final arguments = call.arguments;
      final changedMedia = (arguments is List ? arguments : const [])
          .map(PlaybackMediaKey.tryParse)
          .whereType<PlaybackMediaKey>()
          .toList(growable: false);
      // There can be only one player window. Invalidate the cache before the
      // asynchronous library refresh so a new request can never reuse a
      // controller that is already closing.
      _activeController = null;
      await onPlaybackStateChanged(changedMedia);
      return null;
    });
  }

  /// Opens the sole player window or atomically replaces its current session.
  static Future<void> openOrReplace(PlayerWindowRequest request) {
    final operation = _launchQueue.then((_) => _openOrReplace(request));
    _launchQueue = operation.catchError((_) {});
    return operation;
  }

  static Future<void> _openOrReplace(PlayerWindowRequest request) async {
    final existing = await _findActiveController();
    if (existing != null) {
      try {
        final result = await existing.invokeMethod<Map<Object?, Object?>>('player.replaceRequest', request.encode());
        if (result?['ready'] != true) {
          throw const _PlayerWindowRequestRejected();
        }
        await existing.invokeMethod<void>('player.activate');
        return;
      } on _PlayerWindowRequestRejected {
        rethrow;
      } catch (error) {
        debugPrint('复用播放器窗口失败，正在回收旧窗口: $error');
        await _retireController(existing);
      }
    }

    final controller = await _open(request);
    _activeController = controller;
    await _waitUntilReady(controller);
  }

  static Future<WindowController?> _findActiveController() async {
    final controllers = await WindowController.getAll();
    final activeController = _activeController;
    if (activeController != null && controllers.any((controller) => controller.windowId == activeController.windowId)) {
      return activeController;
    }
    _activeController = null;

    for (final controller in controllers) {
      if (PlayerWindowRequest.tryDecode(controller.arguments) != null) {
        _activeController = controller;
        return controller;
      }
    }
    return null;
  }

  /// Closes a player whose RPC channel no longer accepts replacement requests.
  ///
  /// Creating another engine while the old one is still alive would leave two
  /// players running. A replacement is therefore allowed only after the old
  /// controller has acknowledged close and disappeared from the window list.
  static Future<void> _retireController(WindowController controller) async {
    try {
      await controller.invokeMethod<void>('player.close');
    } catch (error) {
      throw StateError('无法安全回收现有播放器窗口: $error');
    }

    for (var attempt = 0; attempt < 20; attempt++) {
      final controllers = await WindowController.getAll();
      final stillOpen = controllers.any((candidate) => candidate.windowId == controller.windowId);
      if (!stillOpen) {
        _activeController = null;
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw StateError('现有播放器窗口未能关闭，已取消创建新的播放器窗口。');
  }

  static Future<void> _waitUntilReady(WindowController controller) async {
    for (var attempt = 0; attempt < 20; attempt++) {
      try {
        final result = await controller.invokeMethod<Map<Object?, Object?>>('player.ready');
        if (result?['ready'] == true || result?['state'] == 'ready') return;
        if (result?['state'] == 'failed') {
          throw PlayerWindowLaunchFailed(
            mediaStatus: result?['media'] as String?,
            targetStatus: result?['target'] as String?,
          );
        }
        throw StateError('播放器未能准备媒体请求。');
      } on PlayerWindowLaunchFailed {
        rethrow;
      } catch (_) {
        if (attempt == 19) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
    }
  }
}

class _PlayerWindowRequestRejected implements Exception {
  const _PlayerWindowRequestRejected();

  @override
  String toString() => '播放器无法准备新的媒体请求。';
}

/// A newly created player window already renders this failure itself, so the
/// library window must not add a second error message after receiving it.
class PlayerWindowLaunchFailed implements Exception {
  const PlayerWindowLaunchFailed({this.mediaStatus, this.targetStatus});

  final String? mediaStatus;
  final String? targetStatus;

  @override
  String toString() => [mediaStatus, targetStatus].whereType<String>().where((status) => status.isNotEmpty).join(' · ');
}

/// Bootstraps only playback dependencies; it never builds the library shell or
/// initializes the app router in the child engine.
Future<void> runPlayerWindow(WindowController controller, PlayerWindowRequest request) async {
  await windowManager.ensureInitialized();
  final bootstrap = await _PlayerWindowBootstrap.load(request);
  final session = _PlayerWindowSessionController(bootstrap);
  final closeCoordinator = PlayerWindowCloseCoordinator();
  final lifecycle = _PlayerWindowLifecycle(
    controller: controller,
    closeCoordinator: closeCoordinator,
    session: session,
  );
  await windowManager.setPreventClose(true);
  windowManager.addListener(lifecycle);

  await controller.setWindowMethodHandler((call) async {
    if (call.method == 'player.ready') {
      return <String, Object?>{'windowId': controller.windowId, ...session.readiness()};
    }
    if (call.method == 'player.replaceRequest') {
      final arguments = call.arguments;
      final nextRequest = arguments is String ? PlayerWindowRequest.tryDecode(arguments) : null;
      if (nextRequest == null) {
        throw const FormatException('Invalid player-window request.');
      }
      final nextBootstrap = await session.replace(nextRequest);
      if (nextBootstrap.isReady) {
        lifecycle.reopen();
      }
      return session.readinessFor(nextBootstrap);
    }
    if (call.method == 'player.activate') {
      await controller.show();
      return null;
    }
    if (call.method == 'player.close') {
      unawaited(lifecycle.close());
      return null;
    }
    throw MissingPluginException('Unsupported player-window method: ${call.method}');
  });

  final windowOptions = WindowOptions(
    size: Size(1280, 720),
    minimumSize: Size(720, 405),
    center: true,
    title: 'Mochi Player',
    backgroundColor: Colors.black,
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: Platform.isMacOS,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(_PlayerWindowApp(session: session, closeCoordinator: closeCoordinator, onCloseRequested: lifecycle.close));
}

class _PlayerWindowLifecycle with WindowListener {
  static const _nativeWindowChannel = MethodChannel('mochi_player/window_controls');

  _PlayerWindowLifecycle({required this.controller, required this.closeCoordinator, required this.session});

  final WindowController controller;
  final PlayerWindowCloseCoordinator closeCoordinator;
  final _PlayerWindowSessionController session;
  bool _isClosing = false;
  int _closeGeneration = 0;

  @override
  void onWindowClose() {
    unawaited(close());
  }

  Future<void> close() async {
    if (_isClosing) return;
    _isClosing = true;
    final closeGeneration = ++_closeGeneration;
    try {
      await closeCoordinator.flushProgress();
      if (closeGeneration != _closeGeneration) return;
      session.close();
      await WidgetsBinding.instance.endOfFrame;
      if (closeGeneration != _closeGeneration) return;
      await _notifyMainWindow();
      if (closeGeneration != _closeGeneration) return;
      await _closeWindow();
    } finally {
      if (closeGeneration == _closeGeneration) {
        _isClosing = false;
      }
    }
  }

  void reopen() {
    _closeGeneration++;
    _isClosing = false;
  }

  Future<void> _closeWindow() async {
    if (Platform.isWindows) {
      await windowManager.setPreventClose(false);
      await windowManager.close();
      return;
    }

    if (Platform.isMacOS) {
      await windowManager.setPreventClose(false);
      await _nativeWindowChannel.invokeMethod<void>('closePlayerWindow');
      return;
    }

    await controller.hide();
  }

  Future<void> _notifyMainWindow() async {
    final changedMedia = session.bootstrap.mediaStore.changedMedia.map((key) => key.toJson()).toList(growable: false);
    final controllers = await WindowController.getAll();
    for (final candidate in controllers) {
      if (candidate.windowId == controller.windowId || PlayerWindowRequest.tryDecode(candidate.arguments) != null) {
        continue;
      }
      try {
        await candidate.invokeMethod<void>('player.closed', changedMedia);
        return;
      } catch (_) {
        // Another non-player window may not be the parent. Keep looking.
      }
    }
  }
}

class _PlayerWindowSessionController extends ChangeNotifier {
  _PlayerWindowSessionController(this._bootstrap);

  _PlayerWindowBootstrap _bootstrap;
  bool _isOpen = true;

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
    if (!next.isReady) return next;
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

      final initialMedia = await effectiveMediaStore.readMediaFile(
        sourceId: request.initialMedia.sourceId,
        path: request.initialMedia.path,
      );
      if (initialMedia == null) {
        return _PlayerWindowBootstrap._(
          request: request,
          appSettingsProvider: effectiveAppSettingsProvider,
          mediaStore: effectiveMediaStore,
          windowControlsController: effectiveWindowControlsController,
          databaseStatus: '已初始化',
          mediaStatus: '未找到请求的媒体文件',
          targetStatus: '未解析',
        );
      }
      final queue = (await Future.wait(
        request.queue.map(
          (reference) => effectiveMediaStore.readMediaFile(sourceId: reference.sourceId, path: reference.path),
        ),
      )).whereType<MediaFile>().toList(growable: false);
      final target = await StorageSourcePlaybackResolver().resolve(initialMedia);
      return _PlayerWindowBootstrap._(
        request: request,
        appSettingsProvider: effectiveAppSettingsProvider,
        mediaStore: effectiveMediaStore,
        windowControlsController: effectiveWindowControlsController,
        databaseStatus: '已初始化',
        mediaStatus: '已从目录重新读取：${initialMedia.fileName}',
        targetStatus: target == null ? '解析失败' : '已在子窗口解析',
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
        databaseStatus: '失败：$error',
        mediaStatus: '未读取',
        targetStatus: '未解析',
      );
    }
  }
}

class _PlayerWindowApp extends StatelessWidget {
  const _PlayerWindowApp({required this.session, required this.closeCoordinator, required this.onCloseRequested});

  final _PlayerWindowSessionController session;
  final PlayerWindowCloseCoordinator closeCoordinator;
  final Future<void> Function() onCloseRequested;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: session.bootstrap.appSettingsProvider),
        ChangeNotifierProvider.value(value: session.bootstrap.windowControlsController),
        ChangeNotifierProvider.value(value: session),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Mochi Player',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: AppTheme.lightThemeFor(themeProvider.accentColor.color),
            darkTheme: AppTheme.darkThemeFor(themeProvider.accentColor.color),
            home: Consumer<_PlayerWindowSessionController>(
              builder: (context, session, _) => _PlayerWindowHome(
                bootstrap: session.bootstrap,
                isOpen: session.isOpen,
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
    required this.closeCoordinator,
    required this.onCloseRequested,
  });

  final _PlayerWindowBootstrap bootstrap;
  final bool isOpen;
  final PlayerWindowCloseCoordinator closeCoordinator;
  final Future<void> Function() onCloseRequested;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: !isOpen
              ? const ColoredBox(color: Colors.black)
              : bootstrap.isReady
              ? PlayerPage(
                  key: ValueKey(bootstrap.request.requestId),
                  videoItem: bootstrap.initialMedia!,
                  target: bootstrap.initialTarget!,
                  contextTitle: bootstrap.request.contextTitle,
                  playlist: bootstrap.queue,
                  mediaStore: bootstrap.mediaStore,
                  regularMinimumWindowSize: const Size(720, 405),
                  closeCoordinator: closeCoordinator,
                )
              : _PlayerWindowLaunchFailure(bootstrap: bootstrap, onCloseRequested: onCloseRequested),
        ),
        if (WindowsWindowButtons.isSupported && !context.watch<WindowControlsController>().isMiniPlayer)
          const Positioned(top: 0, left: WindowControlsLayout.leadingInset, child: WindowsWindowButtons()),
      ],
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
                const Text('无法打开播放器', style: TextStyle(color: Colors.white, fontSize: 20)),
                const SizedBox(height: 8),
                Text(
                  '${bootstrap.mediaStatus}\n${bootstrap.targetStatus}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                FilledButton(onPressed: onCloseRequested, child: const Text('关闭')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
