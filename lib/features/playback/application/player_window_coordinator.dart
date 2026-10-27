// 【窗口业务编排】串行创建、替换及关闭单个播放器视图。
// 通过注入的窗口工厂工作，重复请求不产生额外播放器。

import 'package:mochi_player/features/playback/domain/player_window_request.dart';

/// 与媒体库处于同一 isolate 的活动播放器视图。
abstract interface class PlayerWindowSession {
  bool get isClosing;
  Future<void> replace(PlayerWindowRequest request);
  Future<void> activate();
  Future<void> close();
}

/// 串行创建、替换及关闭单个播放器视图。
class PlayerWindowCoordinator {
  PlayerWindowCoordinator({required this.createSession});

  final Future<PlayerWindowSession> Function(PlayerWindowRequest request) createSession;
  PlayerWindowSession? _active;
  Future<void> _queue = Future.value();
  bool _shuttingDown = false;

  void beginShutdown() => _shuttingDown = true;

  Future<void> openOrReplace(PlayerWindowRequest request) {
    if (_shuttingDown) return Future.error(StateError('应用正在退出，无法启动播放器。'));
    final operation = _queue.then((_) async {
      _checkRunning();
      var active = _active;
      if (active?.isClosing == true) {
        await active!.close();
        _active = active = null;
        _checkRunning();
      }
      if (active != null) {
        await active.replace(request);
      } else {
        active = await createSession(request);
        _active = active;
      }
      // 创建或地址解析可能在退出开始后才完成；会话仍归此处所有，供 closeAll 收尾，但不能再激活。
      _checkRunning();
      await active.activate();
    });
    _queue = operation.catchError((Object _) {});
    return operation;
  }

  void _checkRunning() {
    if (_shuttingDown) throw StateError('应用正在退出，已取消播放器请求。');
  }

  Future<void> closeAll() async {
    beginShutdown();
    await _queue;
    await _active?.close();
    _active = null;
  }
}

/// 启动错误由播放器视图自行展示，避免主窗口再次弹出提示。
class PlayerWindowLaunchFailure implements Exception {
  const PlayerWindowLaunchFailure();
  @override
  String toString() => 'Player view presents the launch failure.';
}
