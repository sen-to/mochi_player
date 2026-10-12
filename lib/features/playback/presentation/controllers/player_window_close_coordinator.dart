import 'package:flutter/foundation.dart';

/// Coordinates a graceful player-window shutdown without coupling [PlayerPage]
/// to the desktop multi-window implementation.
class PlayerWindowCloseCoordinator {
  PlayerWindowCloseCoordinator({this.stageTimeout = const Duration(seconds: 2)});

  final Duration stageTimeout;
  Future<Map<String, Object?>>? _preparing;

  Future<Map<String, Object?>> prepareClose({
    required Future<void> Function() settleSession,
    required Future<void> Function() detachView,
    required Future<void> Function() closeDatabase,
  }) => _preparing ??= _prepareClose(settleSession, detachView, closeDatabase);

  Future<Map<String, Object?>> _prepareClose(
    Future<void> Function() settleSession,
    Future<void> Function() detachView,
    Future<void> Function() closeDatabase,
  ) async {
    final failedStages = <String>[];
    Future<bool> stage(String name, Future<void> Function() action) async {
      try {
        await Future<void>.sync(action).timeout(stageTimeout);
        return true;
      } catch (_) {
        failedStages.add(name);
        debugPrint('播放器退出阶段失败或超时: $name');
        return false;
      }
    }

    await stage('replacement', settleSession);
    final saved = await stage('progress', flushProgress);
    final released = await stage('resources', releaseResources);
    await stage('frame', detachView);
    await stage('database', closeDatabase);
    return {'prepared': true, 'saved': saved, 'released': released, 'failedStages': failedStages};
  }

  Future<void> Function()? _flushProgress;
  Future<void>? _flushInFlight;
  Future<void> Function()? _releaseResources;
  Future<void>? _releaseInFlight;

  void registerProgressFlusher(Future<void> Function() flusher) {
    _flushProgress = flusher;
    _flushInFlight = null;
  }

  void registerResourceReleaser(Future<void> Function() releaser) {
    _releaseResources = releaser;
    _releaseInFlight = null;
  }

  Future<void> releaseResources() => _releaseInFlight ??= _releaseResources?.call() ?? Future<void>.value();

  void unregisterResourceReleaser() {
    _releaseResources = null;
    _releaseInFlight = null;
  }

  void unregisterProgressFlusher() {
    _flushProgress = null;
    _flushInFlight = null;
  }

  Future<void> flushProgress() async {
    final flusher = _flushProgress;
    if (flusher == null) return;
    final flush = _flushInFlight ??= flusher();
    try {
      await flush;
    } finally {
      if (identical(_flushInFlight, flush)) _flushInFlight = null;
    }
  }
}
