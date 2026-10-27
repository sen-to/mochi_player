// 【持久化映射】在 EpisodeDO 数据库记录与 Episode 业务模型之间转换。
// 数据库字段、枚举存储值和 JSON 转换限于数据层，业务模型不依赖 drift。

import 'package:mochi_player/core/data/database/app_database.dart';
import 'package:mochi_player/core/data/database/mappers/stored_json_mapper.dart';
import 'package:mochi_player/core/domain/media/models.dart';

abstract final class EpisodeMapper {
  static Episode toDomain(EpisodeDO row) => Episode(
    tvShowTmdbId: row.tvShowTmdbId,
    seasonNumber: row.seasonNumber,
    tmdbId: row.tmdbId,
    episodeNumber: row.episodeNumber,
    title: row.title,
    airDate: row.airDate,
    overview: row.overview,
    stillUrl: row.stillUrl,
    guestStars: StoredJsonMapper.decodeArtists(row.guestStars),
  );

  static EpisodeDO toDO(Episode model) => EpisodeDO(
    episodeKey: model.episodeKey,
    tvShowTmdbId: model.tvShowTmdbId,
    seasonNumber: model.seasonNumber,
    tmdbId: model.tmdbId,
    episodeNumber: model.episodeNumber,
    title: model.title,
    airDate: model.airDate,
    overview: model.overview,
    stillUrl: model.stillUrl,
    guestStars: StoredJsonMapper.encodeArtists(model.guestStars),
  );
}
