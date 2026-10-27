// 【应用组装】创建播放器视图并协调挂载、替换和关闭。
// 依赖与会话显式注入，创建失败也必须释放已准备资源。

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mochi_player/core/domain/playback/playback_target_resolver.dart';
import 'package:mochi_player/core/platform/desktop_window_service.dart';
import 'package:mochi_player/core/platform/window_controls_controller.dart';
import 'package:mochi_player/core/platform/window_service.dart';
import 'package:mochi_player/features/playback/application/playback_engine.dart';
import 'package:mochi_player/features/playback/application/playback_media_repository.dart';
import 'package:mochi_player/features/playback/application/player_window_controller.dart';
import 'package:mochi_player/features/playback/application/player_window_coordinator.dart';
import 'package:mochi_player/features/playback/domain/player_window_request.dart';
import 'package:mochi_player/features/playback/ui/controllers/player_window_close_coordinator.dart';
import 'package:mochi_player/features/playback/ui/player_window_app.dart';

Future<PlayerWindowSession> createPlayerWindow({
  required DesktopWindowHost host,
  required PlayerWindowRequest request,
  required PlaybackMediaRepository mediaRepository,
  required PlaybackEngine Function(PlaybackOptions) engineFactory,
  required PlaybackTargetResolver resolver,
}) async {
  final bootstrap = await PlayerWindowBootstrap.load(request, mediaRepository: mediaRepository, resolver: resolver);
  final session = PlayerWindowController(bootstrap);
  final closeCoordinator = PlayerWindowCloseCoordinator();
  final lifecycle = _PlayerWindowLifecycle(session: session, resolver: resolver, closeCoordinator: closeCoordinator);
  const windowSetup = WindowSetup(size: Size(1280, 720), minimumSize: Size(720, 405));
  final WindowService windows;
  try {
    windows = host.create(
      setup: windowSetup,
      builder: (_) => PlayerWindowApp(
        session: session,
        closeCoordinator: closeCoordinator,
        onCloseRequested: lifecycle.close,
        windowControls: lifecycle.windowControls,
        engineFactory: engineFactory,
      ),
    );
  } catch (_) {
    try {
      await bootstrap.playback?.close();
    } finally {
      session.dispose();
    }
    rethrow;
  }
  lifecycle.windows = windows;
  lifecycle.windowControls = WindowControlsController(viewId: windows.viewId);
  try {
    await windows.setPreventClose(true);
    windows.addListener(lifecycle);
    await WidgetsBinding.instance.endOfFrame;
    await lifecycle.windowControls.configureTitlebar(minimumSize: windowSetup.minimumSize);
    return lifecycle;
  } catch (_) {
    // 注册后才失败的创建操作仍持有原生视图；必须先退役该视图，再允许下一次启动。
    await lifecycle.close();
    rethrow;
  }
}

class _PlayerWindowLifecycle with WindowEvents implements PlayerWindowSession {
  _PlayerWindowLifecycle({required this.closeCoordinator, required this.session, required this.resolver});

  late final WindowService windows;
  late final WindowControlsController windowControls;
  final PlayerWindowCloseCoordinator closeCoordinator;
  final PlayerWindowController session;
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
      mediaRepository: session.bootstrap.mediaRepository,
      resolver: resolver,
    );
    var adopted = false;
    try {
      if (!next.isReady) throw StateError('播放器无法准备新的媒体请求。');
      if (isClosing) return;
      await closeCoordinator.flushProgress();
      await closeCoordinator.releaseResources();
      await session.bootstrap.playback?.close();
      if (isClosing) return;
      session.close();
      await WidgetsBinding.instance.endOfFrame;
      if (isClosing) return;
      session.open(next);
      adopted = true;
      await WidgetsBinding.instance.endOfFrame;
    } finally {
      if (!adopted) await next.playback?.close();
    }
  }

  @override
  Future<void> activate() async {
    if (isClosing) return;
    await windows.activate();
    if (!session.bootstrap.isReady) {
      throw const PlayerWindowLaunchFailure();
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
      closeSession: () async => session.bootstrap.playback?.close(),
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
