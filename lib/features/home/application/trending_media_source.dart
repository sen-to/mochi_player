// 【外部能力契约】定义首页需要的趋势和高分条目读取。
// 状态管理不依赖 TMDB 客户端，具体服务适配由 data 实现。

import 'package:mochi_player/core/domain/media/trending_item.dart';

abstract interface class TrendingMediaSource {
  bool get isConfigured;
  Future<List<TrendingItem>> fetchTrendingMovies({int limit = 3});
  Future<List<TrendingItem>> fetchTrendingTV({int limit = 3});
  Future<List<TrendingItem>> fetchTopRated({int limit = 3});
}
