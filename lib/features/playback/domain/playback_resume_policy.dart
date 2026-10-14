import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/media/watch_progress_policy.dart';

/// Decides whether playback should resume and where it should start.
class PlaybackResumePolicy {
  static const Duration backoff = Duration(seconds: 5);

  static Duration? positionFor(MediaFile item, {required bool hasRestoredPosition}) {
    if (hasRestoredPosition || item.position <= 0) return null;
    if (WatchProgressPolicy.isCompleted(item.position, item.duration)) {
      return null;
    }

    final positionMs = (item.position - backoff.inMilliseconds).clamp(0, item.position).toInt();
    return positionMs > 0 ? Duration(milliseconds: positionMs) : null;
  }
}
