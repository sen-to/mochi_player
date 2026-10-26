import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/infrastructure/tmdb/tmdb_client.dart';
import 'package:mochi_player/core/infrastructure/tmdb/tmdb_failure.dart';
import 'package:mochi_player/core/infrastructure/tmdb/tmdb_metadata_mapper.dart';
import 'package:mochi_player/core/infrastructure/tmdb/tmdb_search_matcher.dart';
import 'package:mochi_player/core/infrastructure/tmdb/tmdb_season_result.dart';

/// Coordinates TMDB requests, result matching and metadata conversion.
class TmdbService {
  TmdbService({TmdbClient? client})
    : _client = client ?? TmdbClient(),
      _mapper = const TmdbMetadataMapper(),
      _matcher = const TmdbSearchMatcher();

  final TmdbClient _client;
  final TmdbMetadataMapper _mapper;
  final TmdbSearchMatcher _matcher;

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
    return _mapResponse(() => _mapper.movie(data));
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
    return _mapResponse(() => _mapper.tvShow(data));
  }

  Future<TmdbSeasonResult?> fetchSeason(int tvId, int seasonNumber, {required String showTmdbId}) async {
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
    return _mapResponse(() => _mapper.season(data, showTmdbId, seasonNumber));
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
      () => _results(data).take(limit).map((item) => _mapper.trending(item, forceMovie: isMovie)).toList(),
    );
  }

  Future<Map<String, dynamic>?> _search(String path, String query, {int? year, String yearKey = 'year'}) async {
    final parameters = <String, dynamic>{
      'query': query,
      'include_adult': false,
      // The analyzer used by code generation does not parse the equivalent
      // null-aware map element with a dynamic key.
      // ignore: use_null_aware_elements
      if (year != null) yearKey: year,
    };
    final data = await _client.get(path, operation: '搜索 TMDB: $query', queryParameters: parameters);
    return _matcher.findBest(_results(data), query, isTV: path.contains('/tv'));
  }

  List<Map<String, dynamic>> _results(Map<String, dynamic>? data) {
    // Search and collection endpoints exist even when they contain no items.
    // Their 404 indicates an unavailable endpoint, not an empty collection.
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
