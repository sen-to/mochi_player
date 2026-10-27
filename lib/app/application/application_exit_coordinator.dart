// 【应用生命周期】串行协调退出请求、播放收尾与应用数据写入。
// 重复退出共享同一操作，单阶段失败仍继续后续释放。

import 'dart:async';

/// 播放进度及应用写入排空前保持共享引擎存活；失败不阻止最终退出，也不重复启动退出流程。
class ApplicationExitCoordinator {
  ApplicationExitCoordinator({
    required this.beginShutdown,
    required this.closePlayers,
    required this.cleanUp,
    required this.exitProcess,
    required this.onFailure,
    this.playerTimeout = const Duration(seconds: 18),
    this.cleanupTimeout = const Duration(seconds: 8),
  });

  final void Function() beginShutdown;
  final Future<void> Function() closePlayers;
  final Future<void> Function() cleanUp;
  final void Function() exitProcess;
  final void Function(String stage, Object error) onFailure;
  final Duration playerTimeout;
  final Duration cleanupTimeout;
  bool _isExiting = false;
  Future<void>? _operation;

  bool get isExiting => _isExiting;

  Future<void> requestExit() {
    if (_operation != null) return _operation!;
    _isExiting = true;
    return _operation = Future<void>.sync(_run);
  }

  Future<void> _run() async {
    try {
      beginShutdown();
    } catch (error) {
      onFailure('begin shutdown', error);
    }
    await _stage('player shutdown', closePlayers, playerTimeout);
    await _stage('application cleanup', cleanUp, cleanupTimeout);
    exitProcess();
  }

  Future<void> _stage(String name, Future<void> Function() action, Duration timeout) async {
    try {
      await Future<void>.sync(action).timeout(timeout);
    } catch (error) {
      onFailure(name, error);
    }
  }
}
