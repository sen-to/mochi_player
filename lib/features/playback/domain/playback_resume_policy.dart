// 【播放业务规则】决定是否续播及应回退到的起播位置。
// 只根据文件快照计算，不执行 seek 或写入进度。

import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/media/watch_progress_policy.dart';

/// 决定是否续播，以及应该从哪个位置开始。
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
