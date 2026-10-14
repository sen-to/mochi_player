import 'package:mochi_player/core/domain/media/watch_status.dart';

/// Shared by persistence, resume decisions and progress presentation.
class WatchProgressPolicy {
  static const double completionThreshold = 0.95;

  static bool isCompleted(int position, int duration) => duration > 0 && position >= duration * completionThreshold;

  static WatchStatus statusFor(int position, int duration) => position <= 0
      ? WatchStatus.notStarted
      : isCompleted(position, duration)
      ? WatchStatus.completed
      : WatchStatus.watching;
}
