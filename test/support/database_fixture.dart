// 【测试数据】创建真实 SQLite 测试所需的来源与媒体文件。
// 测试数据保持隔离，不使用用户媒体库。

import 'package:mochi_player/core/data/database/app_database.dart';
import 'package:mochi_player/core/domain/media/models.dart';

/// 为查询测试写入真实父记录，不关闭外键约束。
Future<void> saveMediaFixture(AppDatabase database, List<MediaFile> files) async {
  for (final file in files) {
    if (await database.getStorageSource(file.sourceId) == null) {
      await database.saveStorageSource(
        StorageSourceDO(
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
