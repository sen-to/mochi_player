// 【数据访问】将元数据读取与原子关联导入适配到共享数据库。
// 导入不覆盖用户收藏或观看进度，不负责网络匹配。

import 'package:mochi_player/core/data/database/app_database.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/domain/media/season_metadata.dart';
import 'package:mochi_player/features/library/metadata/application/metadata_repository.dart';

/// 原子导入服务商元数据和匹配关系，不写入用户状态。
class DatabaseMetadataRepository implements MetadataRepository {
  DatabaseMetadataRepository({required AppDatabase database}) : _database = database;
  final AppDatabase _database;

  @override
  Future<Movie?> findMovie(String id) => _database.getMovieByTmdbId(id);

  @override
  Future<TVShow?> findTVShow(String id) => _database.getTVShowByTmdbId(id);

  @override
  Future<bool> importMovie(Movie movie, MediaFile file) => _database.transaction(() async {
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
  Future<bool> importTVShow(TVShow show) => _database.transaction(() async {
    final isNew = await _database.getTVShowByTmdbId(show.tmdbId) == null;
    await _database.saveTVShowMetadata(show);
    return isNew;
  });

  @override
  Future<Set<String>> importSeasonEpisodes(SeasonMetadata result, String showId, List<MediaFile> files) =>
      _database.transaction(() async {
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
