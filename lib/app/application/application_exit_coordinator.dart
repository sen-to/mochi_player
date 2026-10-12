import 'dart:async';

/// Keeps the main engine alive until child progress and application writes have
/// drained. Failures never prevent process termination or cause a second exit.
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
