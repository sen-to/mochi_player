// 【界面状态】加载并发布首页趋势、剧集和高分列表。
// 配置刷新使旧请求失效；销毁后不更新界面状态。

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:mochi_player/core/domain/media/trending_item.dart';
import 'package:mochi_player/features/home/application/trending_media_source.dart';

/// 加载并发布首页展示的非持久化 TMDB 集合。
class TrendingMediaProvider extends ChangeNotifier {
  TrendingMediaProvider({required TrendingMediaSource source}) : _source = source;

  final TrendingMediaSource _source;
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

  /// TMDB 是否已配置；请求尚未返回时，首页据此保留趋势区域。
  bool get isConfigured => _source.isConfigured;

  bool get hasContent => _movies.isNotEmpty || _tvShows.isNotEmpty || _topRated.isNotEmpty;

  /// 普通加载共用请求；配置变化时即使旧请求仍在进行，也会保留一次最新配置刷新。
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
          if (!_source.isConfigured) {
            _movies = [];
            _tvShows = [];
            _topRated = [];
          } else {
            final results = await Future.wait([
              _source.fetchTrendingMovies(limit: 3),
              _source.fetchTrendingTV(limit: 3),
              _source.fetchTopRated(limit: 3),
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
