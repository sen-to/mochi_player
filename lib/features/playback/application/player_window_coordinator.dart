import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mochi_player/core/platform/window_service.dart';
import 'package:mochi_player/features/playback/application/playback_media_store.dart';
import 'package:mochi_player/features/playback/domain/player_window_request.dart';

/// Serializes player sessions without exposing the native window backend.
class PlayerWindowCoordinator {
  PlayerWindowCoordinator(
    this.windows, {
    this.launchTimeout = const Duration(seconds: 10),
    this.closeTimeout = const Duration(seconds: 12),
  });
  final WindowService windows;
  final Duration launchTimeout;
  final Duration closeTimeout;
  WindowHandle? _active;
  Future<void> _launchQueue = Future<void>.value();
  bool _shuttingDown = false;

  void beginShutdown() => _shuttingDown = true;

  Future<void> installMainWindowHandler(
    WindowHandle main, {
    required Future<void> Function(List<PlaybackMediaKey>) onPlaybackStateChanged,
  }) => main.setHandler((call) async {
    if (call.method != 'player.closed') throw MissingPluginException('Unsupported main-window method: ${call.method}');
    final payload = call.arguments as Map;
    if (_active?.id == payload['windowId']) _active = null;
    final changed = (payload['changedMedia'] as List)
        .map(PlaybackMediaKey.tryParse)
        .whereType<PlaybackMediaKey>()
        .toList(growable: false);
    if (!_shuttingDown) await onPlaybackStateChanged(changed);
    return null;
  });

  Future<void> openOrReplace(PlayerWindowRequest request) {
    if (_shuttingDown) return Future.error(StateError('应用正在退出，无法启动播放器。'));
    final operation = _launchQueue.then((_) => _openOrReplace(request));
    _launchQueue = operation.catchError((Object _) {});
    return operation;
  }

  void _checkRunning() {
    if (_shuttingDown) throw StateError('应用正在退出，已取消播放器请求。');
  }

  Future<void> _openOrReplace(PlayerWindowRequest request) async {
    _checkRunning();
    final existing = await _findActive();
    _checkRunning();
    if (existing != null) {
      try {
        final result = await existing.invoke<Map<Object?, Object?>>(
          'player.replaceRequest',
          request.encode(),
          launchTimeout,
        );
        _checkRunning();
        if (result?['state'] == 'closing') throw StateError('播放器正在关闭。');
        if (result?['ready'] != true) throw const _PlayerWindowRequestRejected();
        await existing.invoke<void>('player.activate');
        return;
      } on _PlayerWindowRequestRejected {
        rethrow;
      } catch (error) {
        _checkRunning();
        debugPrint('复用播放器窗口失败，正在回收旧窗口: $error');
        await _retire(existing);
      }
    }
    _checkRunning();
    final created = await windows.create(request.encode()).timeout(launchTimeout);
    _active = created;
    // A native creation already in flight cannot be cancelled. Keep its handle
    // discoverable for shutdown, but never activate or replace it after exit.
    _checkRunning();
    await _waitUntilReady(created).timeout(launchTimeout);
    _checkRunning();
  }

  Future<WindowHandle?> _findActive() async {
    final all = await windows.getAll().timeout(launchTimeout);
    final active = _active;
    if (active != null && all.any((window) => window.id == active.id)) return active;
    _active = null;
    for (final window in all) {
      if (PlayerWindowRequest.tryDecode(window.arguments) != null) return _active = window;
    }
    return null;
  }

  Future<void> _retire(WindowHandle window) async {
    final report = await window.invoke<Map<Object?, Object?>>('player.prepareClose', null, closeTimeout);
    if (report?['prepared'] != true) throw StateError('播放器未确认关闭准备完成。');
    if (report?['saved'] != true || report?['released'] != true) {
      debugPrint('播放器关闭清理未完整成功: ${report?['failedStages']}');
    }
    await window.invoke<void>('player.close');
    await _waitUntilGone(window);
    if (_active?.id == window.id) _active = null;
  }

  Future<void> _waitUntilGone(WindowHandle window) async {
    final deadline = DateTime.now().add(const Duration(seconds: 3));
    do {
      final all = await windows.getAll().timeout(const Duration(seconds: 1));
      if (!all.any((candidate) => candidate.id == window.id)) return;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    } while (DateTime.now().isBefore(deadline));
    throw StateError('播放器窗口未能关闭。');
  }

  /// Main process termination is the final fallback if a child is hung. Do not
  /// start a second player to compensate for a missing acknowledgement.
  Future<void> closeAll() async {
    beginShutdown();
    try {
      await _launchQueue.timeout(const Duration(seconds: 2));
    } on TimeoutException {
      // Continue discovering windows even if a native launch is still stuck.
      // A late-created child is terminated with the process at the deadline.
      debugPrint('播放器启动未及时收尾，继续执行应用退出。');
    }
    final all = await windows.getAll().timeout(const Duration(seconds: 1));
    for (final window in all) {
      if (PlayerWindowRequest.tryDecode(window.arguments) != null) {
        await _retire(window);
      }
    }
  }

  Future<void> _waitUntilReady(WindowHandle window) async {
    for (var attempt = 0; attempt < 20; attempt++) {
      _checkRunning();
      try {
        final result = await window.invoke<Map<Object?, Object?>>('player.ready');
        if (result?['ready'] == true) return;
        if (result?['state'] == 'failed') {
          throw PlayerWindowLaunchFailed(
            mediaStatus: result?['media'] as String?,
            targetStatus: result?['target'] as String?,
          );
        }
      } on PlayerWindowLaunchFailed {
        rethrow;
      } catch (_) {
        if (attempt == 19) rethrow;
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    throw StateError('播放器未能准备媒体请求。');
  }
}

class _PlayerWindowRequestRejected implements Exception {
  const _PlayerWindowRequestRejected();
  @override
  String toString() => '播放器无法准备新的媒体请求。';
}

/// The child already presents this failure; do not show another library toast.
class PlayerWindowLaunchFailed implements Exception {
  const PlayerWindowLaunchFailed({this.mediaStatus, this.targetStatus});
  final String? mediaStatus;
  final String? targetStatus;
  @override
  String toString() => [mediaStatus, targetStatus].whereType<String>().where((status) => status.isNotEmpty).join(' · ');
}
