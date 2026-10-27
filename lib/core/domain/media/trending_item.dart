// 【服务结果模型】描述 TMDB 趋势条目的标题、图片和评分。
// 由共享 TMDB 服务返回，不持久化为本地媒体文件。

/// 共享 TMDB 服务返回的趋势条目摘要；供首页消费，不是界面格式化后的 VO。
class TrendingItem {
  final String tmdbId;
  final String title;
  final String? posterUrl;
  final String? backdropUrl;
  final String? overview;
  final double rating;
  final int? releaseYear;
  final List<String> genres;
  final bool isMovie;

  const TrendingItem({
    required this.tmdbId,
    required this.title,
    this.posterUrl,
    this.backdropUrl,
    this.overview,
    this.rating = 0.0,
    this.releaseYear,
    this.genres = const [],
    required this.isMovie,
  });
}
