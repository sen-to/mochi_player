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

/// Selects the episode a TV show should play according to watch progression.
///
/// An unfinished latest episode resumes in place. A completed latest episode
/// advances to the next local episode that has not already been completed.
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
