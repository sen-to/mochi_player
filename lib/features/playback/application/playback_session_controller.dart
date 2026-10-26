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

/// Owns target preparation, backend lifetime and resource release for one session.
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
      // Engine construction can fail synchronously before the page registers
      // close callbacks. Cleanup remains owned by this prepared session.
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
      _operation = operation.then<void>((_) {}, onError: (Object _, StackTrace __) {});
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

  /// Prepares a target before a view or backend exists. The session owns it now.
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
        // An open failure alone does not establish that the backend is idle.
        // Stop explicitly before dropping either the old or attempted target.
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
      // Persistence failure must not prevent playback of another item.
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
      // _open either completed the replacement, stopped, or disposed the engine.
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

  /// Also closes prepared sessions whose page never mounted. Late resolutions
  /// release themselves; backend disposal precedes release of active targets.
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
