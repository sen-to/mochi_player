import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/domain/media/season_metadata.dart';
import 'package:mochi_player/core/infrastructure/database/database_service.dart';
import 'package:mochi_player/features/library/metadata/metadata_repository.dart';

/// Imports provider metadata and matches atomically, without writing user state.
class DatabaseMetadataRepository implements MetadataRepository {
  DatabaseMetadataRepository({required DatabaseService database}) : _database = database;
  final DatabaseService _database;

  @override
  Future<Movie?> findMovie(String id) => _database.getMovieByTmdbId(id);

  @override
  Future<TVShow?> findTVShow(String id) => _database.getTVShowByTmdbId(id);

  @override
  Future<bool> importMovie(Movie movie, MediaFile file) => _database.database.transaction(() async {
    final isNew = await _database.getMovieByTmdbId(movie.tmdbId) == null;
    await _database.saveMovieMetadata(movie);
    await _database.updateMediaMatches([
      file.copyWith(
        movieTmdbId: movie.tmdbId,
        tvShowTmdbId: null,
        episodeKey: null,
        metadataMatchStatus: MetadataMatchStatus.confirmed,
      ),
    ]);
    return isNew;
  });

  @override
  Future<bool> importTVShow(TVShow show) => _database.database.transaction(() async {
    final isNew = await _database.getTVShowByTmdbId(show.tmdbId) == null;
    await _database.saveTVShowMetadata(show);
    return isNew;
  });

  @override
  Future<Set<String>> importSeasonEpisodes(SeasonMetadata result, String showId, List<MediaFile> files) =>
      _database.database.transaction(() async {
        if (result.season.tvShowTmdbId != showId) {
          throw ArgumentError('Season does not belong to the requested show');
        }
        await _database.saveSeasonEpisodes(result.season, result.episodes);
        final episodes = {for (final episode in result.episodes) episode.episodeNumber: episode};
        final matches = [
          for (final file in files)
            if (file.parsedSeason == result.season.seasonNumber && episodes.containsKey(file.parsedEpisode))
              file.copyWith(
                movieTmdbId: null,
                tvShowTmdbId: showId,
                episodeKey: episodes[file.parsedEpisode]!.episodeKey,
                metadataMatchStatus: MetadataMatchStatus.confirmed,
              ),
        ];
        await _database.updateMediaMatches(matches);
        return matches.map((file) => file.storageKey).toSet();
      });

  @override
  Future<void> markUnmatched(List<MediaFile> files) => _database.updateMediaMatches([
    for (final file in files)
      file.copyWith(
        movieTmdbId: null,
        tvShowTmdbId: null,
        episodeKey: null,
        metadataMatchStatus: MetadataMatchStatus.unmatched,
      ),
  ]);
}
