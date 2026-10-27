// 【展示对象 VO】保存详情页面使用的展示字段和操作上下文。
// 不从业务模型取值或处理回退；转换统一由 MediaDetailMapper 完成。

import 'package:mochi_player/core/domain/media/models.dart';

class MediaDetailVO {
  const MediaDetailVO({
    required this.item,
    required this.movie,
    required this.tvShow,
    required this.tmdbId,
    required this.title,
    required this.overview,
    required this.backdropUrl,
    required this.posterUrl,
    required this.logoUrl,
    required this.genres,
    required this.rating,
    required this.releaseYear,
    required this.certification,
    required this.cast,
    required this.totalSeasonCount,
    required this.seasons,
  });

  final LibraryItem item;
  final Movie? movie;
  final TVShow? tvShow;
  final String tmdbId;
  final String title;
  final String? overview;
  final String backdropUrl;
  final String posterUrl;
  final String? logoUrl;
  final List<String> genres;
  final double rating;
  final int? releaseYear;
  final String? certification;
  final List<Artist> cast;
  final int? totalSeasonCount;
  final List<Season> seasons;
  bool get isMovie => movie != null;
  bool get isTVShow => tvShow != null;
}
