// 【持久化映射】在 SeasonDO 数据库记录与 Season 业务模型之间转换。
// 数据库字段、枚举存储值和 JSON 转换限于数据层，业务模型不依赖 drift。

import 'package:mochi_player/core/data/database/app_database.dart';
import 'package:mochi_player/core/domain/media/models.dart';

abstract final class SeasonMapper {
  static Season toDomain(SeasonDO row) => Season(
    tvShowTmdbId: row.tvShowTmdbId,
    seasonNumber: row.seasonNumber,
    title: row.title,
    posterUrl: row.posterUrl,
    overview: row.overview,
    numberOfEpisodes: row.numberOfEpisodes,
  );

  static SeasonDO toDO(Season model) => SeasonDO(
    tvShowTmdbId: model.tvShowTmdbId,
    seasonNumber: model.seasonNumber,
    title: model.title,
    posterUrl: model.posterUrl,
    overview: model.overview,
    numberOfEpisodes: model.numberOfEpisodes,
  );
}
