// 【展示映射】将业务媒体条目转换为详情页面的展示对象。
// 空图片回退和电影／剧集字段选择只在映射层处理，VO 本身只保存数据。

import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/features/library/detail/ui/media_detail_vo.dart';

abstract final class MediaDetailMapper {
  static MediaDetailVO toVO(LibraryItem item) {
    final movie = item is Movie ? item : null;
    final show = item is TVShow ? item : null;
    return MediaDetailVO(
      item: item,
      movie: movie,
      tvShow: show,
      tmdbId: item.tmdbId,
      title: item.title,
      overview: item.overview,
      backdropUrl: item.backdropUrl ?? '',
      posterUrl: item.posterUrl ?? '',
      logoUrl: item.logoUrl,
      genres: List.unmodifiable(item.genres),
      rating: item.rating,
      releaseYear: item.releaseYear,
      certification: item.certification,
      cast: List.unmodifiable(item.cast),
      totalSeasonCount: show?.numberOfSeasons,
      seasons: List.unmodifiable(show?.seasons ?? const <Season>[]),
    );
  }
}
