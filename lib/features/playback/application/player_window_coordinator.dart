import 'package:mochi_player/features/playback/domain/player_window_request.dart';

/// A live playback view in the same isolate as the library.
abstract interface class PlayerWindowSession {
  bool get isClosing;
  Future<void> replace(PlayerWindowRequest request);
  Future<void> activate();
  Future<void> close();
}

/// Serializes creation, replacement and shutdown of the single player view.
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
      // Creation/resolution may finish after shutdown started. Its session stays
      // owned here so closeAll can drain it, but it must never be activated.
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

/// The player view presents its own launch error, avoiding a second toast.
class PlayerWindowLaunchFailed implements Exception {
  const PlayerWindowLaunchFailed();
  @override
  String toString() => 'Player view presents the launch failure.';
}
