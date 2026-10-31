// 【持久化契约】定义已有元数据读取及元数据与文件关联的原子导入。
// 不暴露数据库事务回调，具体 SQL 留在 data 实现中。

import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/domain/media/season_metadata.dart';

/// 只操作本地元数据，读取失败和导入失败均抛出异常，不返回伪造的未匹配结果。
/// 每次导入独立原子提交；收藏、观看位置等用户状态不被导入快照覆盖。
abstract interface class MetadataRepository {
  /// id 是电影 TMDB ID；本地不存在时返回 null，不发起网络补查。
  Future<Movie?> findMovie(String id);

  /// id 是剧集 TMDB ID；本地不存在时返回 null，不发起网络补查。
  Future<TVShow?> findTVShow(String id);

  /// 原子保存电影元数据和文件关联；调用方须传入已入库、来源有效的文件。
  /// true 表示电影标题首次入库，false 表示更新已有标题；两者都代表提交成功。
  /// 失败抛出异常并回滚，返回值不是成功 / 失败标志。
  Future<bool> importMovie(Movie movie, MediaFile file);

  /// 保存剧级元数据，不导入季集或更改文件关联。
  /// true 表示剧标题首次入库，false 表示更新已有标题；失败抛出异常并回滚。
  Future<bool> importTVShow(TVShow show);

  /// showId 是所属剧 TMDB ID，须与 metadata.season 的归属一致，否则抛出异常。
  /// 原子导入季集，并只关联季号和集号确切匹配的已有文件。
  /// 返回成功关联文件的 storageKey 集合；空集合表示没有匹配文件，并非导入失败。
  Future<Set<String>> importSeasonEpisodes(SeasonMetadata metadata, String showId, List<MediaFile> files);

  /// 清除指定已有文件的元数据关联并标记为未匹配，不删除元数据或修改用户状态。
  /// 仅用于已确认没有匹配结果的情况，网络请求失败不应调用此方法。
  Future<void> markUnmatched(List<MediaFile> files);
}
