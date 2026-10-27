// 【窗口关闭编排】协调进度保存、页面退役、会话释放及窗口关闭。
// 各阶段设有等待边界，页面不直接实现原生窗口销毁。

import 'package:flutter/foundation.dart';

/// 协调播放器窗口的正常关闭，避免 [PlayerPage] 依赖桌面多窗口具体实现。
class PlayerWindowCloseCoordinator {
  PlayerWindowCloseCoordinator({
    this.stageTimeout = const Duration(seconds: 2),
    // 进入和离开 AppKit 全屏动画都可能耗时最多五秒。
    this.resourceTimeout = const Duration(seconds: 12),
  });

  final Duration stageTimeout;
  final Duration resourceTimeout;
  Future<PlayerWindowCloseReport>? _preparing;

  Future<PlayerWindowCloseReport> prepareClose({
    required Future<void> Function() settleSession,
    required Future<void> Function() closeSession,
    required Future<void> Function() detachView,
  }) => _preparing ??= _prepareClose(settleSession, closeSession, detachView);

  Future<PlayerWindowCloseReport> _prepareClose(
    Future<void> Function() settleSession,
    Future<void> Function() closeSession,
    Future<void> Function() detachView,
  ) async {
    final failedStages = <String>[];
    Future<bool> stage(String name, Future<void> Function() action, {Duration? timeout}) async {
      try {
        await Future<void>.sync(action).timeout(timeout ?? stageTimeout);
        return true;
      } catch (_) {
        failedStages.add(name);
        debugPrint('播放器退出阶段失败或超时: $name');
        return false;
      }
    }

    await stage('replacement', settleSession);
    final saved = await stage('progress', flushProgress);
    final released = await stage(
      'resources',
      () async => Future.wait([Future<void>.sync(releaseResources), Future<void>.sync(closeSession)]),
      timeout: resourceTimeout,
    );
    await stage('frame', detachView);
    return PlayerWindowCloseReport(saved: saved, released: released, failedStages: failedStages);
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

class PlayerWindowCloseReport {
  const PlayerWindowCloseReport({required this.saved, required this.released, required this.failedStages});
  final bool saved;
  final bool released;
  final List<String> failedStages;
}
