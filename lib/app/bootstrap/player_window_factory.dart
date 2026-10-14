import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mochi_player/core/domain/playback/playback_target_resolver.dart';
import 'package:mochi_player/core/platform/desktop_window_service.dart';
import 'package:mochi_player/core/platform/window_controls_controller.dart';
import 'package:mochi_player/core/platform/window_service.dart';
import 'package:mochi_player/features/playback/application/playback_engine.dart';
import 'package:mochi_player/features/playback/application/playback_media_store.dart';
import 'package:mochi_player/features/playback/application/player_window_coordinator.dart';
import 'package:mochi_player/features/playback/application/player_window_state.dart';
import 'package:mochi_player/features/playback/domain/player_window_request.dart';
import 'package:mochi_player/features/playback/presentation/player_window_app.dart';
import 'package:mochi_player/features/playback/presentation/controllers/player_window_close_coordinator.dart';

Future<PlayerWindowSession> createPlayerWindow({
  required DesktopWindowHost host,
  required PlayerWindowRequest request,
  required PlaybackMediaStore mediaStore,
  required PlaybackEngine Function(PlaybackOptions) engineFactory,
  required PlaybackTargetResolver resolver,
}) async {
  final bootstrap = await PlayerWindowBootstrap.load(request, mediaStore: mediaStore, resolver: resolver);
  final session = PlayerWindowState(bootstrap);
  final closeCoordinator = PlayerWindowCloseCoordinator();
  final lifecycle = _PlayerWindowLifecycle(session: session, resolver: resolver, closeCoordinator: closeCoordinator);
  final windows = host.create(
    setup: const WindowSetup(size: Size(1280, 720), minimumSize: Size(720, 405)),
    builder: (_) => PlayerWindowApp(
      session: session,
      closeCoordinator: closeCoordinator,
      onCloseRequested: lifecycle.close,
      windowControls: lifecycle.windowControls,
      engineFactory: engineFactory,
      resolver: resolver,
    ),
  );
  lifecycle.windows = windows;
  lifecycle.windowControls = WindowControlsController(viewId: windows.viewId);
  try {
    await windows.setPreventClose(true);
    windows.addListener(lifecycle);
    await WidgetsBinding.instance.endOfFrame;
    await lifecycle.windowControls.configureTitlebar();
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
  final PlayerWindowState session;
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
    final next = await PlayerWindowBootstrap.load(
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
