// 【共享业务规则】根据观看历史选择续播、下一集或从头播放的本地单集。
// 详情页和媒体库播放入口复用，不负责解析播放地址。

import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/media/media_type.dart';
import 'package:mochi_player/core/domain/media/watch_status.dart';

enum EpisodePlaybackReason { resumeEpisode, playNext, startFromBeginning }

class EpisodePlaybackTarget {
  final MediaFile file;
  final EpisodePlaybackReason reason;
  final DateTime? activityAt;

  const EpisodePlaybackTarget({required this.file, required this.reason, required this.activityAt});

  bool get resumesCurrentEpisode => reason == EpisodePlaybackReason.resumeEpisode;
}

/// 按观看进度选择要播放的单集；最近观看但未完成时续播，已完成时寻找后续本地未完成单集。
class EpisodePlaybackTargetResolver {
  const EpisodePlaybackTargetResolver._();

  static EpisodePlaybackTarget? resolveForShowPlayback(Iterable<MediaFile> files) => _resolve(files, allowReplay: true);

  static EpisodePlaybackTarget? resolveForContinueWatching(Iterable<MediaFile> files) =>
      _resolve(files, allowReplay: false);

  static EpisodePlaybackTarget? _resolve(Iterable<MediaFile> files, {required bool allowReplay}) {
    final episodes = files.where((file) => file.mediaType == MediaType.episode).toList()..sort(_compareEpisodes);
    if (episodes.isEmpty) return null;

    final watched =
        episodes.where((file) => file.watchStatus != WatchStatus.notStarted && file.lastWatchedAt != null).toList()
          ..sort((a, b) => b.lastWatchedAt!.compareTo(a.lastWatchedAt!));

    if (watched.isNotEmpty) {
      final latest = watched.first;
      if (latest.watchStatus == WatchStatus.watching) {
        return EpisodePlaybackTarget(
          file: latest,
          reason: EpisodePlaybackReason.resumeEpisode,
          activityAt: latest.lastWatchedAt,
        );
      }

      final latestIndex = episodes.indexOf(latest);
      for (var index = latestIndex + 1; index < episodes.length; index++) {
        final candidate = episodes[index];
        if (_sameEpisode(candidate, latest) || candidate.watchStatus == WatchStatus.completed) {
          continue;
        }
        return EpisodePlaybackTarget(
          file: candidate,
          reason: EpisodePlaybackReason.playNext,
          activityAt: latest.lastWatchedAt,
        );
      }
    }

    if (!allowReplay) return null;

    MediaFile? firstIncomplete;
    for (final episode in episodes) {
      if (episode.watchStatus != WatchStatus.completed) {
        firstIncomplete = episode;
        break;
      }
    }
    return EpisodePlaybackTarget(
      file: firstIncomplete ?? episodes.first,
      reason: EpisodePlaybackReason.startFromBeginning,
      activityAt: watched.isEmpty ? null : watched.first.lastWatchedAt,
    );
  }

  static int _compareEpisodes(MediaFile a, MediaFile b) {
    final season = (a.parsedSeason ?? 999999).compareTo(b.parsedSeason ?? 999999);
    if (season != 0) return season;

    final episode = (a.parsedEpisode ?? 999999).compareTo(b.parsedEpisode ?? 999999);
    if (episode != 0) return episode;

    return a.path.toLowerCase().compareTo(b.path.toLowerCase());
  }

  static bool _sameEpisode(MediaFile a, MediaFile b) {
    if (a.episodeKey != null && a.episodeKey == b.episodeKey) return true;
    return a.parsedSeason != null &&
        a.parsedEpisode != null &&
        a.parsedSeason == b.parsedSeason &&
        a.parsedEpisode == b.parsedEpisode;
  }
}
