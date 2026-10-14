import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/infrastructure/database/app_database.dart';
import 'package:mochi_player/core/infrastructure/database/database_service.dart';

/// Persists real parent rows for query fixtures; never disables FK enforcement.
Future<void> saveMediaFixture(DatabaseService database, List<MediaFile> files) async {
  for (final file in files) {
    if (await database.getStorageSource(file.sourceId) == null) {
      await database.saveStorageSource(
        StorageSourceRow(
          sourceId: file.sourceId,
          name: file.sourceId,
          type: 'local',
          endpoint: '/media',
          rootPath: '/',
          enabled: true,
          username: '',
          password: '',
        ),
      );
    }
    final movieId = file.movieTmdbId;
    if (movieId != null && await database.getMovieByTmdbId(movieId) == null) {
      await database.saveMovieMetadata(Movie(tmdbId: movieId, title: file.parsedTitle));
    }
    final showId = file.tvShowTmdbId;
    if (showId != null) {
      if (await database.getTVShowByTmdbId(showId) == null) {
        await database.saveTVShowMetadata(TVShow(tmdbId: showId, title: file.parsedTitle));
      }
      if (file.episodeKey != null) {
        await database.saveSeasonEpisodes(
          Season(tvShowTmdbId: showId, seasonNumber: file.parsedSeason!, title: 'Season'),
          [
            Episode(
              tvShowTmdbId: showId,
              seasonNumber: file.parsedSeason!,
              episodeNumber: file.parsedEpisode!,
              title: 'Episode',
            ),
          ],
        );
      }
    }
  }
  await database.saveScannedFiles(files);
}
