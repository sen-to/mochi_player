import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/playback/playback_target.dart';
import 'package:mochi_player/core/domain/playback/playback_target_resolver.dart';
import 'package:mochi_player/core/infrastructure/storage/storage_source_playback_resolver.dart';
import 'package:mochi_player/features/playback/application/playback_media_store.dart';
import 'package:mochi_player/features/playback/application/playback_progress_writer.dart';
import 'package:mochi_player/features/playback/domain/playback_queue.dart';

/// Coordinates playback data for a single page session.
///
/// This controller deliberately has no dependency on Flutter widgets or the
/// media backend. The page remains responsible for rendering and issuing the
/// actual open/seek commands to media_kit.
class PlaybackSessionController {
  PlaybackSessionController({
    required PlaybackMediaStore mediaStore,
    required MediaFile initialItem,
    required List<MediaFile> queueItems,
    required PlaybackTarget initialTarget,
    PlaybackTargetResolver? resolver,
  }) : _mediaStore = mediaStore,
       _resolver = resolver ?? StorageSourcePlaybackResolver(),
       _queue = PlaybackQueue(initialItem: initialItem, items: queueItems),
       _currentTarget = initialTarget,
       _progressWriter = PlaybackProgressWriter(mediaStore.updateProgress);

  final PlaybackMediaStore _mediaStore;
  final PlaybackTargetResolver _resolver;
  final PlaybackQueue _queue;
  final PlaybackProgressWriter _progressWriter;
  PlaybackTarget _currentTarget;
  int _lastSavedPositionMs = -1;
  bool _isSwitching = false;

  MediaFile get currentItem => _queue.current;

  PlaybackTarget get currentTarget => _currentTarget;

  bool get hasPrevious => _queue.hasPrevious;

  bool get hasNext => _queue.hasNext;

  bool get isSwitching => _isSwitching;

  Future<void> refreshCurrentItem() async {
    final itemAtRequest = currentItem;
    final latestItem = await _mediaStore.readMediaFile(sourceId: itemAtRequest.sourceId, path: itemAtRequest.path);
    if (latestItem != null && _isCurrent(itemAtRequest)) {
      _queue.replaceCurrent(latestItem);
    }
  }

  bool _isCurrent(MediaFile item) =>
      currentItem.id == item.id || (currentItem.sourceId == item.sourceId && currentItem.path == item.path);

  Future<void> saveProgress({required int positionMs, required int durationMs, bool force = false}) async {
    if (positionMs <= 0 && durationMs <= 0) return;
    final delta = (positionMs - _lastSavedPositionMs).abs();
    if (!force && _lastSavedPositionMs >= 0 && delta < 5000) return;

    _lastSavedPositionMs = positionMs;
    await _progressWriter.save(currentItem, positionMs, duration: durationMs > 0 ? durationMs : null);
  }

  Future<PlaybackQueueMoveResult?> moveBy(int offset, {required int positionMs, required int durationMs}) async {
    if (_isSwitching) return null;
    final targetItem = _queue.itemAtOffset(offset);
    if (targetItem == null) return null;

    _isSwitching = true;
    try {
      try {
        await saveProgress(positionMs: positionMs, durationMs: durationMs, force: true);
      } catch (_) {
        // Playback can continue even when persistence is temporarily down.
      }
      final target = await _resolver.resolve(targetItem);
      if (target == null) {
        return PlaybackQueueMoveResult.failed(targetItem);
      }

      _queue.selectOffset(offset);
      _currentTarget = target;
      _lastSavedPositionMs = -1;
      return PlaybackQueueMoveResult.ready(targetItem);
    } finally {
      _isSwitching = false;
    }
  }
}

class PlaybackQueueMoveResult {
  const PlaybackQueueMoveResult._({required this.item, this.isReady = false});

  factory PlaybackQueueMoveResult.ready(MediaFile item) => PlaybackQueueMoveResult._(item: item, isReady: true);

  factory PlaybackQueueMoveResult.failed(MediaFile item) => PlaybackQueueMoveResult._(item: item);

  final MediaFile item;
  final bool isReady;
}
