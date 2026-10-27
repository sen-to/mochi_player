// 【共享业务规则】根据播放位置与时长推导观看进度和完成状态。
// 数据库写入、续播与进度展示使用同一规则。

import 'package:mochi_player/core/domain/media/watch_status.dart';

/// 持久化、续播决策和进度展示共同使用的规则。
class WatchProgressPolicy {
  static const double completionThreshold = 0.95;

  static bool isCompleted(int position, int duration) => duration > 0 && position >= duration * completionThreshold;

  static WatchStatus statusFor(int position, int duration) => position <= 0
      ? WatchStatus.notStarted
      : isCompleted(position, duration)
      ? WatchStatus.completed
      : WatchStatus.watching;
}
