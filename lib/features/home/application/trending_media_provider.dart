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

  List<TrendingItem> get movies => _movies;

  List<TrendingItem> get tvShows => _tvShows;

  List<TrendingItem> get topRated => _topRated;

  bool get isLoading => _isLoading;

  /// Whether TMDB has been configured. The home page uses this to reserve the
  /// trending section while a configured endpoint is still returning data.
  bool get isConfigured => _tmdbService.isConfigured;

  bool get hasContent => _movies.isNotEmpty || _tvShows.isNotEmpty || _topRated.isNotEmpty;

  Future<void> fetch() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      if (!_tmdbService.isConfigured) {
        _movies = [];
        _tvShows = [];
        _topRated = [];
        return;
      }

      final results = await Future.wait([
        _tmdbService.fetchTrendingMovies(limit: 3),
        _tmdbService.fetchTrendingTV(limit: 3),
        _tmdbService.fetchTopRated(limit: 3),
      ]);
      _movies = results[0];
      _tvShows = results[1];
      _topRated = results[2];
      _logger.i(
        '加载热门趋势: 电影 ${_movies.length}, 剧集 ${_tvShows.length}, '
        '高分 ${_topRated.length}',
      );
    } catch (error, stackTrace) {
      _logger.e('加载热门趋势失败', error: error, stackTrace: stackTrace);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
