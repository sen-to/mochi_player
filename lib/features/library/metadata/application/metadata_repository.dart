// 【持久化契约】定义已有元数据读取及元数据与文件关联的原子导入。
// 不暴露数据库事务回调，具体 SQL 留在 data 实现中。

import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/domain/media/season_metadata.dart';

/// 读取本地元数据，并原子导入元数据及文件关联。
abstract interface class MetadataRepository {
  Future<Movie?> findMovie(String id);
  Future<TVShow?> findTVShow(String id);

  /// 返回此标题是否为新导入。
  Future<bool> importMovie(Movie movie, MediaFile file);
  Future<bool> importTVShow(TVShow show);

  /// 返回已匹配到确切单集的文件存储键。
  Future<Set<String>> importSeasonEpisodes(SeasonMetadata metadata, String showId, List<MediaFile> files);

  Future<void> markUnmatched(List<MediaFile> files);
}
