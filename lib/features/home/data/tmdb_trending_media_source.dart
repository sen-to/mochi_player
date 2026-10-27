// 【外部服务适配】将 TMDB 趋势接口适配为首页读取能力。
// 网络实现保留在数据层，Provider 只消费条目与请求结果。

import 'package:mochi_player/core/data/tmdb/tmdb_api.dart';
import 'package:mochi_player/core/domain/media/trending_item.dart';
import 'package:mochi_player/features/home/application/trending_media_source.dart';

class TmdbTrendingMediaSource implements TrendingMediaSource {
  TmdbTrendingMediaSource(this._api);
  final TmdbApi _api;
  @override
  bool get isConfigured => _api.isConfigured;
  @override
  Future<List<TrendingItem>> fetchTrendingMovies({int limit = 3}) => _api.fetchTrendingMovies(limit: limit);
  @override
  Future<List<TrendingItem>> fetchTrendingTV({int limit = 3}) => _api.fetchTrendingTV(limit: limit);
  @override
  Future<List<TrendingItem>> fetchTopRated({int limit = 3}) => _api.fetchTopRated(limit: limit);
}
