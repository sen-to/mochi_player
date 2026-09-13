import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/media/models.dart';

void main() {
  test('resumes the latest unfinished episode', () {
    final target = EpisodePlaybackTargetResolver.resolveForShowPlayback([
      _episode(1, status: WatchStatus.watching, watchedMinute: 2),
      _episode(2),
    ]);

    expect(target?.file.parsedEpisode, 1);
    expect(target?.reason, EpisodePlaybackReason.resumeEpisode);
  });

  test('advances from a completed episode to the next local episode', () {
    final target = EpisodePlaybackTargetResolver.resolveForShowPlayback([
      _episode(1, status: WatchStatus.completed, watchedMinute: 3),
      _episode(2),
      _episode(3),
    ]);

    expect(target?.file.parsedEpisode, 2);
    expect(target?.reason, EpisodePlaybackReason.playNext);
  });

  test('advances across seasons and skips episodes already completed', () {
    final target = EpisodePlaybackTargetResolver.resolveForShowPlayback([
      _episode(10, season: 1, status: WatchStatus.completed, watchedMinute: 3),
      _episode(1, season: 2, status: WatchStatus.completed, watchedMinute: 2),
      _episode(2, season: 2),
    ]);

    expect(target?.file.parsedSeason, 2);
    expect(target?.file.parsedEpisode, 2);
  });

  test('omits a fully watched show from continue watching', () {
    final target = EpisodePlaybackTargetResolver.resolveForContinueWatching([
      _episode(1, status: WatchStatus.completed, watchedMinute: 2),
      _episode(2, status: WatchStatus.completed, watchedMinute: 3),
    ]);

    expect(target, isNull);
  });

  test('omits a show that has never been played from continue watching', () {
    final target = EpisodePlaybackTargetResolver.resolveForContinueWatching([_episode(1), _episode(2)]);

    expect(target, isNull);
  });
}

MediaFile _episode(int episode, {int season = 1, WatchStatus status = WatchStatus.notStarted, int? watchedMinute}) {
  return MediaFile(
    id: season * 100 + episode,
    path: '/show/s${season}e$episode.mkv',
    fileName: 's${season}e$episode.mkv',
    parsedTitle: 'Show',
    parsedSeason: season,
    parsedEpisode: episode,
    mediaType: MediaType.episode,
    tvShowTmdbId: '10',
    episodeTmdbId: '10_s${season}e$episode',
    duration: 60 * 60 * 1000,
    position: status == WatchStatus.completed ? 60 * 60 * 1000 : 10 * 60 * 1000,
    watchStatus: status,
    lastWatchedAt: watchedMinute == null ? null : DateTime(2026, 8, 1, 12, watchedMinute),
    addedAt: DateTime(2026, 8, 1),
  );
}
