import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:mochi_player/core/domain/media/trending_item.dart';
import 'package:mochi_player/core/infrastructure/tmdb/tmdb_service.dart';

/// Loads and exposes the non-persistent TMDB collections shown on the home page.
class TrendingMediaProvider extends ChangeNotifier {
  TrendingMediaProvider({required TmdbService tmdbService}) : _tmdbService = tmdbService;

  final TmdbService _tmdbService;
  final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  List<TrendingItem> _movies = [];
  List<TrendingItem> _tvShows = [];
  List<TrendingItem> _topRated = [];
  bool _isLoading = false;
  bool _disposed = false;
  bool _refreshPending = false;
  int _configurationGeneration = 0;
  Future<void>? _fetching;

  List<TrendingItem> get movies => _movies;

  List<TrendingItem> get tvShows => _tvShows;

  List<TrendingItem> get topRated => _topRated;

  bool get isLoading => _isLoading;

  /// Whether TMDB has been configured. The home page uses this to reserve the
  /// trending section while a configured endpoint is still returning data.
  bool get isConfigured => _tmdbService.isConfigured;

  bool get hasContent => _movies.isNotEmpty || _tvShows.isNotEmpty || _topRated.isNotEmpty;

  /// Shares ordinary loads; a configuration change requests the latest data
  /// even when the previous endpoint still has an outstanding request.
  Future<void> fetch({bool refresh = false}) {
    if (_disposed) return Future<void>.value();
    if (refresh) {
      _configurationGeneration++;
      _refreshPending = true;
    }
    return _fetching ??= _fetch().whenComplete(() => _fetching = null);
  }

  Future<void> _fetch() async {
    _isLoading = true;
    notifyListeners();
    try {
      do {
        _refreshPending = false;
        final generation = _configurationGeneration;
        try {
          if (!_tmdbService.isConfigured) {
            _movies = [];
            _tvShows = [];
            _topRated = [];
          } else {
            final results = await Future.wait([
              _tmdbService.fetchTrendingMovies(limit: 3),
              _tmdbService.fetchTrendingTV(limit: 3),
              _tmdbService.fetchTopRated(limit: 3),
            ]);
            if (_disposed) return;
            if (generation != _configurationGeneration) continue;
            _movies = results[0];
            _tvShows = results[1];
            _topRated = results[2];
            _logger.i(
              '加载热门趋势: 电影 ${_movies.length}, 剧集 ${_tvShows.length}, '
              '高分 ${_topRated.length}',
            );
          }
        } catch (error, stackTrace) {
          if (!_disposed && generation == _configurationGeneration) {
            _logger.e('加载热门趋势失败', error: error, stackTrace: stackTrace);
          }
        }
      } while (_refreshPending && !_disposed);
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _configurationGeneration++;
    _refreshPending = false;
    super.dispose();
  }
}
