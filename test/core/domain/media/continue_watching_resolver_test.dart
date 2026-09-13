import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/media/models.dart';

void main() {
  test('returns one progressing target per show and one version per movie', () {
    final targets = ContinueWatchingResolver.resolve([
      _file(
        path: '/show/s01e01.mkv',
        title: 'Show',
        tmdbId: '10_s1e1',
        type: MediaType.episode,
        season: 1,
        episode: 1,
        status: WatchStatus.completed,
        watchedMinute: 4,
      ),
      _file(path: '/show/s01e02.mkv', title: 'Show', tmdbId: '10_s1e2', type: MediaType.episode, season: 1, episode: 2),
      _file(
        path: '/movie/1080p.mkv',
        title: 'Movie',
        tmdbId: '20',
        type: MediaType.movie,
        status: WatchStatus.watching,
        watchedMinute: 2,
      ),
      _file(
        path: '/movie/2160p.mkv',
        title: 'Movie',
        tmdbId: '20',
        type: MediaType.movie,
        status: WatchStatus.watching,
        watchedMinute: 3,
      ),
    ]);

    expect(targets.map((target) => target.file.path), ['/show/s01e02.mkv', '/movie/2160p.mkv']);
  });

  test('omits new and fully watched shows', () {
    final targets = ContinueWatchingResolver.resolve([
      _file(
        path: '/new/s01e01.mkv',
        title: 'New Show',
        tmdbId: '30_s1e1',
        type: MediaType.episode,
        season: 1,
        episode: 1,
      ),
      _file(
        path: '/done/s01e01.mkv',
        title: 'Done Show',
        tmdbId: '40_s1e1',
        type: MediaType.episode,
        season: 1,
        episode: 1,
        status: WatchStatus.completed,
        watchedMinute: 5,
      ),
    ]);

    expect(targets, isEmpty);
  });
}

MediaFile _file({
  required String path,
  required String title,
  required String? tmdbId,
  required MediaType type,
  int? season,
  int? episode,
  WatchStatus status = WatchStatus.notStarted,
  int? watchedMinute,
}) {
  return MediaFile(
    id: path.hashCode,
    path: path,
    fileName: path.split('/').last,
    parsedTitle: title,
    parsedSeason: season,
    parsedEpisode: episode,
    mediaType: type,
    movieTmdbId: type == MediaType.movie ? tmdbId : null,
    tvShowTmdbId: type == MediaType.episode ? RegExp(r'^(\d+)_s').firstMatch(tmdbId ?? '')?.group(1) : null,
    episodeTmdbId: type == MediaType.episode ? tmdbId : null,
    duration: 3600000,
    position: status == WatchStatus.completed ? 3600000 : 600000,
    watchStatus: status,
    lastWatchedAt: watchedMinute == null ? null : DateTime(2026, 8, 1, 12, watchedMinute),
    addedAt: DateTime(2026, 8, 1),
  );
}
