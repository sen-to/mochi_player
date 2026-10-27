// 【播放会话编排】统一准备目标、打开与切换媒体、保存进度及释放资源。
// 会话拥有引擎和目标资源，失败与关闭都从此入口收尾。

import 'dart:async';

import 'package:mochi_player/core/domain/app_failure.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/playback/playback_target.dart';
import 'package:mochi_player/core/domain/playback/playback_target_resolver.dart';
import 'package:mochi_player/features/playback/application/playback_engine.dart';
import 'package:mochi_player/features/playback/application/playback_media_repository.dart';
import 'package:mochi_player/features/playback/application/playback_progress_writer.dart';
import 'package:mochi_player/features/playback/domain/playback_queue.dart';
import 'package:mochi_player/features/playback/domain/playback_resume_policy.dart';

/// 统一持有一个会话的目标准备、后端生命周期与资源释放。
class PlaybackSessionController {
  PlaybackSessionController({
    required PlaybackMediaRepository mediaRepository,
    required MediaFile initialItem,
    required List<MediaFile> queueItems,
    required PlaybackTargetResolver resolver,
  }) : _mediaRepository = mediaRepository,
       _resolver = resolver,
       _queue = PlaybackQueue(initialItem: initialItem, items: queueItems),
       _progressWriter = PlaybackProgressWriter(mediaRepository.updateProgress);

  final PlaybackMediaRepository _mediaRepository;
  final PlaybackTargetResolver _resolver;
  final PlaybackQueue _queue;
  final PlaybackProgressWriter _progressWriter;
  final Set<PlaybackTarget> _targets = {};
  final Map<PlaybackTarget, Future<void>> _releases = {};
  PlaybackTarget? _currentTarget;
  PlaybackEngine? _engine;
  PlaybackOptions? _options;
  Future<void>? _operation;
  Future<void>? _closeFuture;
  Future<void>? _preparation;
  int _lastSavedPositionMs = -1;
  bool _busy = false;
  bool _closing = false;
  bool _mediaLoaded = false;

  MediaFile get currentItem => _queue.current;
  PlaybackTarget get currentTarget => _currentTarget ?? (throw StateError('Playback target is not prepared.'));
  String? get currentUrl => _currentTarget?.url;
  bool get hasPrevious => _queue.hasPrevious;
  bool get hasNext => _queue.hasNext;
  bool get isSwitching => _busy;
  bool get isClosed => _closeFuture != null;

  PlaybackEngine attachEngine(PlaybackEngine Function(PlaybackOptions) factory, PlaybackOptions options) {
    if (_closing || _engine != null) throw StateError('Playback session cannot attach another engine.');
    _options = options;
    try {
      return _engine = factory(options);
    } catch (_) {
      // 页面注册关闭回调前，引擎构造就可能同步失败；清理仍由已准备的会话负责。
      unawaited(close().catchError((Object _) {}));
      rethrow;
    }
  }

  void beginShutdown() {
    _closing = true;
    _engine?.cancelPendingCommands();
  }

  Future<void> prepareClose() {
    beginShutdown();
    return _preparation ??= _prepareClose();
  }

  Future<void> _prepareClose() async {
    try {
      await _operation;
      if (_closeFuture != null) return;
      await _engine?.pause();
    } finally {
      final snapshot = _engine?.state;
      if (snapshot != null) {
        await saveProgress(
          positionMs: snapshot.position.inMilliseconds,
          durationMs: snapshot.duration.inMilliseconds,
          force: true,
        );
      }
      await _progressWriter.drain();
    }
  }

  Future<T?> _run<T>(Future<T?> Function() action) async {
    if (_closing || _busy) return null;
    _busy = true;
    try {
      final operation = action();
      _operation = operation.then<void>((_) {}, onError: (Object _, StackTrace _) {});
      return await operation;
    } finally {
      _operation = null;
      _busy = false;
    }
  }

  Future<PlaybackTarget?> _resolve(MediaFile item) async {
    final target = await _resolver.resolve(item);
    if (target == null) return null;
    _targets.add(target);
    if (_closing) {
      await _release(target);
      return null;
    }
    return target;
  }

  /// 视图或后端创建前先准备目标；目标从此由会话持有。
  Future<bool> prepare() async =>
      await _run<bool>(() async {
        _currentTarget ??= await _resolve(currentItem);
        return _currentTarget != null && !_closing;
      }) ??
      false;

  Future<void> _refreshCurrentItem() async {
    final itemAtRequest = currentItem;
    final latestItem = await _mediaRepository.readMediaFile(sourceId: itemAtRequest.sourceId, path: itemAtRequest.path);
    if (!_closing &&
        latestItem != null &&
        currentItem.sourceId == itemAtRequest.sourceId &&
        currentItem.path == itemAtRequest.path) {
      _queue.replaceCurrent(latestItem);
    }
  }

  Future<void> saveProgress({required int positionMs, required int durationMs, bool force = false}) async {
    if (!_mediaLoaded || (positionMs <= 0 && durationMs <= 0)) return;
    final delta = (positionMs - _lastSavedPositionMs).abs();
    if (!force && _lastSavedPositionMs >= 0 && delta < 5000) return;
    _lastSavedPositionMs = positionMs;
    await _progressWriter.save(currentItem, positionMs, duration: durationMs > 0 ? durationMs : null);
  }

  Future<Duration?> openCurrent({required bool subtitleStyleOverride}) =>
      _run<Duration>(() => _open(subtitleStyleOverride));

  Future<Duration?> _open(bool subtitleStyleOverride, {void Function()? onMediaChanged}) async {
    final engine = _engine ?? (throw StateError('Playback engine is not attached.'));
    final target = currentTarget;
    _mediaLoaded = false;
    try {
      await _refreshCurrentItem();
      if (_closing) return null;
      final start = PlaybackResumePolicy.positionFor(currentItem, hasRestoredPosition: false);
      onMediaChanged?.call();
      await engine.applyOptions(_options!);
      if (_closing) return null;
      await engine.setSubtitleStyleOverride(subtitleStyleOverride);
      if (_closing) return null;
      await engine.open(target, start: start);
      if (_closing) return null;
      _mediaLoaded = true;
      return start;
    } catch (_) {
      if (!_closing) {
        // 打开失败不能证明后端已空闲；释放旧目标或尝试中的目标前必须显式停止。
        try {
          await engine.stop();
        } catch (_) {
          await close();
          rethrow;
        }
        await _release(target);
        _currentTarget = null;
      }
      rethrow;
    }
  }

  Future<PlaybackQueueMoveResult?> moveBy(
    int offset, {
    required bool subtitleStyleOverride,
    void Function()? onMediaChanged,
  }) => _run<PlaybackQueueMoveResult>(() async {
    final item = _queue.itemAtOffset(offset);
    if (item == null) return null;
    final engine = _engine ?? (throw StateError('Playback engine is not attached.'));
    try {
      await saveProgress(
        positionMs: engine.state.position.inMilliseconds,
        durationMs: engine.state.duration.inMilliseconds,
        force: true,
      );
    } catch (_) {
      // 持久化失败不能阻止播放另一个条目。
    }
    if (_closing) return null;
    final PlaybackTarget? target;
    try {
      target = await _resolve(item);
    } catch (_) {
      return _closing ? null : PlaybackQueueMoveResult.failed(item, AppFailure.playbackLink);
    }
    if (_closing) return null;
    if (target == null) return PlaybackQueueMoveResult.failed(item, AppFailure.playbackLink);

    final previous = _currentTarget;
    _currentTarget = target;
    _queue.selectOffset(offset);
    _lastSavedPositionMs = -1;
    _mediaLoaded = false;
    try {
      final start = await _open(subtitleStyleOverride, onMediaChanged: onMediaChanged);
      return _closing ? null : PlaybackQueueMoveResult.ready(item, start);
    } catch (_) {
      return PlaybackQueueMoveResult.failed(item, AppFailure.playbackOpen);
    } finally {
      // 打开流程已完成替换、停止或销毁引擎，此时才释放旧目标。
      if (_closing) {
        await close();
      } else if (previous != null && !identical(previous, target)) {
        await _release(previous);
      }
    }
  });

  Future<void> _release(PlaybackTarget target) {
    final pending = _releases[target];
    if (pending != null) return pending;
    if (!_targets.remove(target)) return Future.value();
    final release = Future<void>.sync(target.release);
    _releases[target] = release;
    return release.whenComplete(() => _releases.remove(target));
  }

  /// 页面从未挂载的已准备会话也需关闭；迟到解析自行释放，先销毁后端，再释放活动目标。
  Future<void> close() {
    beginShutdown();
    return _closeFuture ??= _close();
  }

  Future<void> _close() async {
    _mediaLoaded = false;
    try {
      await _engine?.dispose();
    } finally {
      await Future.wait([..._targets.toList().map(_release), ..._releases.values]);
    }
  }
}

class PlaybackQueueMoveResult {
  const PlaybackQueueMoveResult._(this.item, this.failure, this.resumePosition);
  factory PlaybackQueueMoveResult.ready(MediaFile item, Duration? start) =>
      PlaybackQueueMoveResult._(item, null, start);
  factory PlaybackQueueMoveResult.failed(MediaFile item, AppFailure failure) =>
      PlaybackQueueMoveResult._(item, failure, null);

  final MediaFile item;
  final AppFailure? failure;
  final Duration? resumePosition;
  bool get isReady => failure == null;
}
