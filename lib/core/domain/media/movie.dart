// 【共享模型】描述电影标题、年份、评分、演员与图片。
// 不执行查询、持久化或界面操作。

import 'package:mochi_player/core/domain/media/artist.dart';
import 'package:mochi_player/core/domain/media/library_item.dart';

/// 电影 Domain Model
class Movie implements LibraryItem {
  @override
  final String tmdbId;
  @override
  final String title;
  @override
  final String? originalTitle;
  @override
  final int? releaseYear;
  final DateTime? releaseDate;
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

  const Movie({
    required this.tmdbId,
    required this.title,
    this.originalTitle,
    this.releaseYear,
    this.releaseDate,
    this.posterUrl,
    this.backdropUrl,
    this.logoUrl,
    this.overview,
    this.certification,
    this.rating = 0.0,
    this.genres = const [],
    this.cast = const [],
  });
}
