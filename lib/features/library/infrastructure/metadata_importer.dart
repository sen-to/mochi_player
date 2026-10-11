import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/infrastructure/database/database_service.dart';
import 'package:mochi_player/core/infrastructure/tmdb/tmdb_season_result.dart';

/// Imports provider metadata and matches atomically, without writing user state.
class MetadataImporter {
  MetadataImporter({DatabaseService? database}) : _database = database ?? DatabaseService();
  final DatabaseService _database;

  Future<bool> importMovie(Movie movie, MediaFile file) => _database.database.transaction(() async {
    final isNew = await _database.getMovieByTmdbId(movie.tmdbId) == null;
    await _database.saveMovieMetadata(movie);
    await _database.updateMediaMatches([
      file.copyWith(
        movieTmdbId: movie.tmdbId,
        tvShowTmdbId: null,
        episodeTmdbId: null,
        metadataMatchStatus: MetadataMatchStatus.confirmed,
      ),
    ]);
    return isNew;
  });

  Future<bool> importTVShow(TVShow show) async {
    final isNew = await _database.getTVShowByTmdbId(show.tmdbId) == null;
    await _database.saveTVShowMetadata(show);
    return isNew;
  }

  Future<Set<String>> importSeasonEpisodes(TmdbSeasonResult result, String showId, List<MediaFile> files) =>
      _database.database.transaction(() async {
        await _database.saveSeasonEpisodes(result.season, result.episodes);
        final episodes = {for (final episode in result.episodes) episode.episodeNumber: episode};
        final matches = [
          for (final file in files)
            if (episodes.containsKey(file.parsedEpisode))
              file.copyWith(
                movieTmdbId: null,
                tvShowTmdbId: showId,
                episodeTmdbId: episodes[file.parsedEpisode]!.tmdbId,
                metadataMatchStatus: MetadataMatchStatus.confirmed,
              ),
        ];
        await _database.updateMediaMatches(matches);
        return matches.map((file) => file.storageKey).toSet();
      });

  Future<void> markUnmatched(List<MediaFile> files) => _database.updateMediaMatches([
    for (final file in files)
      file.copyWith(
        movieTmdbId: null,
        tvShowTmdbId: null,
        episodeTmdbId: null,
        metadataMatchStatus: MetadataMatchStatus.unmatched,
      ),
  ]);
}
