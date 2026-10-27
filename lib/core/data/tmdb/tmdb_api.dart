// 【外部服务入口】组合 TMDB 端点请求、响应校验与业务对象转换。
// 使用注入的客户端；业务导入与数据库事务由媒体库负责。

import 'package:mochi_player/core/data/tmdb/tmdb_failure.dart';
import 'package:mochi_player/core/data/tmdb/tmdb_http_client.dart';
import 'package:mochi_player/core/data/tmdb/tmdb_metadata_mapper.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/domain/media/season_metadata.dart';

/// 提供电影、剧集、季详情和趋势等 TMDB API 能力。
class TmdbApi {
  TmdbApi({TmdbHttpClient? client}) : _client = client ?? TmdbHttpClient(), _mapper = const TmdbMetadataMapper();

  final TmdbHttpClient _client;
  final TmdbMetadataMapper _mapper;

  bool get isConfigured => _client.isConfigured;

  void configure({String? apiKey, String? apiBaseUrl, String? proxyUrl, bool? proxyEnabled}) {
    _client.configure(apiKey: apiKey, apiBaseUrl: apiBaseUrl, proxyUrl: proxyUrl, proxyEnabled: proxyEnabled);
  }

  Future<Movie?> fetchMovie(String title, {int? year}) async {
    final match = await _search('/search/movie', title, year: year);
    final id = match?['id'] as int?;
    return id == null ? null : fetchMovieById(id);
  }

  Future<Movie?> fetchMovieById(int movieId) async {
    final data = await _client.get(
      '/movie/$movieId',
      operation: '获取电影详情',
      queryParameters: const {
        'append_to_response': 'credits,release_dates,images',
        'include_image_language': 'zh,en,null',
      },
    );
    if (data == null) return null;
    if (data['id'] != movieId || data['title'] is! String) {
      throw const TmdbFailure(TmdbFailureKind.invalidResponse);
    }
    return _mapResponse(() => _mapper.movieFromJson(data));
  }

  Future<TVShow?> fetchTVShow(String title, {int? year}) async {
    final match = await _search('/search/tv', title, year: year, yearKey: 'first_air_date_year');
    final id = match?['id'] as int?;
    return id == null ? null : fetchTVShowById(id);
  }

  Future<TVShow?> fetchTVShowById(int tvId) async {
    final data = await _client.get(
      '/tv/$tvId',
      operation: '获取剧集详情',
      queryParameters: const {
        'append_to_response': 'credits,content_ratings,images',
        'include_image_language': 'zh,en,null',
      },
    );
    if (data == null) return null;
    if (data['id'] != tvId || data['name'] is! String) {
      throw const TmdbFailure(TmdbFailureKind.invalidResponse);
    }
    return _mapResponse(() => _mapper.tvShowFromJson(data));
  }

  Future<SeasonMetadata?> fetchSeason(int tvId, int seasonNumber, {required String showTmdbId}) async {
    final data = await _client.get(
      '/tv/$tvId/season/$seasonNumber',
      operation: '获取季详情',
      notFoundMessage: 'TMDB 未找到季详情: ID:$tvId S$seasonNumber',
    );
    if (data == null) return null;
    final episodes = data['episodes'];
    if (episodes is! List || episodes.any((item) => item is! Map<String, dynamic> || item['episode_number'] is! int)) {
      throw const TmdbFailure(TmdbFailureKind.invalidResponse);
    }
    return _mapResponse(() => _mapper.seasonFromJson(data, showTmdbId, seasonNumber));
  }

  Future<List<TrendingItem>> fetchTrendingMovies({int limit = 3}) =>
      _fetchTrendingList('/trending/movie/week', operation: '获取热门电影', isMovie: true, limit: limit);

  Future<List<TrendingItem>> fetchTrendingTV({int limit = 3}) =>
      _fetchTrendingList('/trending/tv/week', operation: '获取热门剧集', isMovie: false, limit: limit);

  Future<List<TrendingItem>> fetchTopRated({int limit = 3}) =>
      _fetchTrendingList('/movie/top_rated', operation: '获取高分佳作', isMovie: true, limit: limit);

  Future<List<TrendingItem>> _fetchTrendingList(
    String path, {
    required String operation,
    required bool isMovie,
    required int limit,
  }) async {
    final data = await _client.get(path, operation: operation);
    return _mapResponse(
      () => _results(data).take(limit).map((item) => _mapper.trendingFromJson(item, forceMovie: isMovie)).toList(),
    );
  }

  Future<Map<String, dynamic>?> _search(String path, String query, {int? year, String yearKey = 'year'}) async {
    final parameters = <String, dynamic>{
      'query': query,
      'include_adult': false,
      // 代码生成所用分析器无法解析带动态键的等价空值感知映射写法。
      // ignore: use_null_aware_elements
      if (year != null) yearKey: year,
    };
    final data = await _client.get(path, operation: '搜索 TMDB: $query', queryParameters: parameters);
    // 标题与年份已作为请求参数传入，直接遵循 TMDB 的候选排序。
    return _results(data).firstOrNull;
  }

  List<Map<String, dynamic>> _results(Map<String, dynamic>? data) {
    // 搜索和集合接口即使没有条目也应存在；其 404 表示接口不可用，而不是空集合。
    if (data == null) throw const TmdbFailure(TmdbFailureKind.invalidResponse, statusCode: 404);
    final results = data['results'];
    if (results is! List || results.any((item) => item is! Map<String, dynamic> || item['id'] is! int)) {
      throw const TmdbFailure(TmdbFailureKind.invalidResponse);
    }
    return results.cast<Map<String, dynamic>>();
  }

  T _mapResponse<T>(T Function() map) {
    try {
      return map();
    } on TypeError {
      throw const TmdbFailure(TmdbFailureKind.invalidResponse);
    } on FormatException {
      throw const TmdbFailure(TmdbFailureKind.invalidResponse);
    }
  }
}
