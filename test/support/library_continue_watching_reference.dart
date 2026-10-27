import 'package:mochi_player/core/domain/media/episode_playback_target_resolver.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/media/media_type.dart';
import 'package:mochi_player/core/domain/media/watch_status.dart';

class LibraryContinueWatchingTarget {
  final MediaFile file;
  final DateTime activityAt;

  const LibraryContinueWatchingTarget({required this.file, required this.activityAt});
}

/// Produces one ordered continue-watching target per logical title.
class LibraryContinueWatchingReference {
  const LibraryContinueWatchingReference._();

  static List<LibraryContinueWatchingTarget> resolve(Iterable<MediaFile> files) {
    final targets = <LibraryContinueWatchingTarget>[];
    final episodeGroups = <String, List<MediaFile>>{};
    final movieGroups = <String, List<MediaFile>>{};

    for (final file in files) {
      switch (file.mediaType) {
        case MediaType.episode:
          episodeGroups.putIfAbsent(_showKey(file), () => []).add(file);
          continue;
        case MediaType.movie:
          movieGroups.putIfAbsent(_movieKey(file), () => []).add(file);
          continue;
        case MediaType.folder:
        case MediaType.unknown:
          if (file.watchStatus == WatchStatus.watching) {
            targets.add(_target(file));
          }
          continue;
      }
    }

    for (final episodes in episodeGroups.values) {
      final episodeTarget = EpisodePlaybackTargetResolver.resolveForContinueWatching(episodes);
      if (episodeTarget == null) continue;
      targets.add(
        LibraryContinueWatchingTarget(file: episodeTarget.file, activityAt: episodeTarget.activityAt ?? DateTime(0)),
      );
    }

    for (final versions in movieGroups.values) {
      final watching = versions.where((file) => file.watchStatus == WatchStatus.watching).toList()
        ..sort(_compareActivityDescending);
      if (watching.isNotEmpty) targets.add(_target(watching.first));
    }

    targets.sort((a, b) => b.activityAt.compareTo(a.activityAt));
    return targets;
  }

  static LibraryContinueWatchingTarget _target(MediaFile file) {
    return LibraryContinueWatchingTarget(file: file, activityAt: file.lastWatchedAt ?? DateTime(0));
  }

  static int _compareActivityDescending(MediaFile a, MediaFile b) {
    return (b.lastWatchedAt ?? DateTime(0)).compareTo(a.lastWatchedAt ?? DateTime(0));
  }

  static String _movieKey(MediaFile file) => file.movieTmdbId ?? file.storageKey;

  static String _showKey(MediaFile file) {
    final showId = file.tvShowTmdbId;
    if (showId != null) return 'tmdb:$showId';

    final title = file.parsedTitle.trim().toLowerCase();
    return title.isEmpty ? 'file:${file.sourceId}:${file.path}' : 'title:$title';
  }
}
