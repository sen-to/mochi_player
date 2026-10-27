// 【共享模型】描述剧集标题、评分、演员及季信息。
// 不执行界面操作或数据查询。

import 'package:mochi_player/core/domain/media/artist.dart';
import 'package:mochi_player/core/domain/media/library_item.dart';
import 'package:mochi_player/core/domain/media/season.dart';

/// 电视剧 Domain Model
class TVShow implements LibraryItem {
  @override
  final String tmdbId;
  @override
  final String title;
  @override
  final String? originalTitle;
  @override
  final int? releaseYear;
  final DateTime? firstAirDate;
  @override
  final String? posterUrl;
  @override
  final String? backdropUrl;
  @override
  final String? logoUrl;
  @override
  final String? overview;
  @override
  final String? certification;
  @override
  final double rating;
  @override
  final List<String> genres;
  @override
  final List<Artist> cast;
  final String? status;
  final int? numberOfSeasons;
  final int? numberOfEpisodes;
  final List<Season> seasons;

  const TVShow({
    required this.tmdbId,
    required this.title,
    this.originalTitle,
    this.releaseYear,
    this.firstAirDate,
    this.posterUrl,
    this.backdropUrl,
    this.logoUrl,
    this.overview,
    this.certification,
    this.rating = 0.0,
    this.genres = const [],
    this.cast = const [],
    this.status,
    this.numberOfSeasons,
    this.numberOfEpisodes,
    this.seasons = const [],
  });

  TVShow withSeasons(List<Season> seasons) => TVShow(
    tmdbId: tmdbId,
    title: title,
    originalTitle: originalTitle,
    releaseYear: releaseYear,
    firstAirDate: firstAirDate,
    posterUrl: posterUrl,
    backdropUrl: backdropUrl,
    logoUrl: logoUrl,
    overview: overview,
    certification: certification,
    rating: rating,
    genres: genres,
    cast: cast,
    status: status,
    numberOfSeasons: numberOfSeasons,
    numberOfEpisodes: numberOfEpisodes,
    seasons: List.unmodifiable(seasons),
  );
}
