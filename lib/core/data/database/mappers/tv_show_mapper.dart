// 【持久化映射】在 TVShowDO 数据库记录与 TVShow 业务模型之间转换。
// 数据库字段、枚举存储值和 JSON 转换限于数据层，业务模型不依赖 drift。

import 'package:mochi_player/core/data/database/app_database.dart';
import 'package:mochi_player/core/data/database/mappers/stored_json_mapper.dart';
import 'package:mochi_player/core/domain/media/models.dart';

abstract final class TVShowMapper {
  static TVShow toDomain(TVShowDO row) => TVShow(
    tmdbId: row.tmdbId,
    title: row.title,
    originalTitle: row.originalTitle,
    releaseYear: row.releaseYear,
    firstAirDate: row.firstAirDate,
    posterUrl: row.posterUrl,
    backdropUrl: row.backdropUrl,
    logoUrl: row.logoUrl,
    overview: row.overview,
    certification: row.certification,
    rating: row.rating,
    genres: StoredJsonMapper.decodeStrings(row.genres),
    cast: StoredJsonMapper.decodeArtists(row.cast),
    status: row.status,
    numberOfSeasons: row.numberOfSeasons,
    numberOfEpisodes: row.numberOfEpisodes,
  );

  static TVShowDO toDO(TVShow model) => TVShowDO(
    tmdbId: model.tmdbId,
    title: model.title,
    originalTitle: model.originalTitle,
    releaseYear: model.releaseYear,
    firstAirDate: model.firstAirDate,
    posterUrl: model.posterUrl,
    backdropUrl: model.backdropUrl,
    logoUrl: model.logoUrl,
    overview: model.overview,
    certification: model.certification,
    rating: model.rating,
    genres: StoredJsonMapper.encodeStrings(model.genres),
    cast: StoredJsonMapper.encodeArtists(model.cast),
    status: model.status,
    numberOfSeasons: model.numberOfSeasons,
    numberOfEpisodes: model.numberOfEpisodes,
  );
}
