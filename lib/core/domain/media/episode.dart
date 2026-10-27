// 【共享模型】描述剧集中的单集信息及身份。
// 本地文件关联与播放选择由相应业务入口处理。

import 'package:mochi_player/core/domain/media/artist.dart';

/// 单集 Domain Model
class Episode {
  final String tvShowTmdbId;
  final int seasonNumber;

  /// 服务商的真实单集 ID，与稳定的剧集／季／集组合键不同。
  final String? tmdbId;
  final int episodeNumber;
  final String title;
  final DateTime? airDate;
  final String? overview;
  final String? stillUrl;
  final List<Artist> guestStars;

  const Episode({
    required this.tvShowTmdbId,
    required this.seasonNumber,
    this.tmdbId,
    required this.episodeNumber,
    required this.title,
    this.airDate,
    this.overview,
    this.stillUrl,
    this.guestStars = const [],
  });

  String get episodeKey => '${tvShowTmdbId}_s${seasonNumber}e$episodeNumber';
}
