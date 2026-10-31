// 【界面状态与功能入口】发布媒体库查询、首页投影及扫描活动。
// 列表查询交给目录仓库，扫描交给同步服务，不公开具体仓库。

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mochi_player/core/domain/app_failure.dart';
import 'package:mochi_player/core/domain/media/library_activity.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/features/library/catalog/application/library_catalog_repository.dart';
import 'package:mochi_player/features/library/catalog/application/media_card_vo.dart';
import 'package:mochi_player/features/library/sync/application/library_sync_service.dart';

/// 媒体库界面入口；持久化记录归 SQLite 管理，此处只保留有限的首页投影。
class MediaLibraryProvider extends ChangeNotifier {
  MediaLibraryProvider({required LibraryCatalogRepository repository, required LibrarySyncService syncService})
    : _repository = repository,
      _sync = syncService {
    _sync.addListener(_relay);
  }

  final LibraryCatalogRepository _repository;
  final LibrarySyncService _sync;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Future<void>? _loading;
  bool _initialized = false;
  bool _disposed = false;
  final _stopping = Completer<void>();
  final _streamErrors = <Object>{};

  void beginShutdown() {
    _disposed = true;
    if (!_stopping.isCompleted) _stopping.complete();
    _sync.beginShutdown();
  }

  Future<void> shutdown() async {
    beginShutdown();
    await _loading;
    await _cancelSubscriptions();
    await _sync.shutdown();
  }

  AppFailure? _loadError;
  int _totalFiles = 0;
  List<LibraryItem> _recentlyAddedContent = const [];
  List<MediaCardVO> _continueWatchingItems = const [];

  int get totalFiles => _totalFiles;
  List<LibraryItem> get recentlyAddedContent => _recentlyAddedContent;
  List<MediaCardVO> get continueWatchingItems => _continueWatchingItems;
  LibraryItem? _hero;

  bool get isLoading => !_initialized || _sync.isLoading;

  AppFailure? get error => _loadError ?? (_streamErrors.isNotEmpty ? AppFailure.contentLoad : null) ?? _sync.error;

  double? get scrapeProgress => _sync.scrapeProgress;

  LibraryActivity? get libraryActivity => _sync.activity;

  bool get hasLibraryContent => recentlyAddedContent.isNotEmpty || continueWatchingItems.isNotEmpty;

  LibraryItem? get heroItem => _hero;

  /// 正常订阅建立后重复调用不重建；有加载错误时取消旧订阅并重新加载。
  Future<void> loadFromDatabase() {
    if (_disposed) return Future<void>.value();
    if (_loading != null) return _loading!;
    if (_initialized && _loadError == null && _streamErrors.isEmpty) return Future<void>.value();
    return _loading = _load().whenComplete(() => _loading = null);
  }

  Future<void> _cancelSubscriptions() async {
    final subscriptions = List.of(_subscriptions);
    _subscriptions.clear();
    await Future.wait(subscriptions.map((subscription) => subscription.cancel()));
  }

  Future<void> _load() async {
    _initialized = false;
    _loadError = null;
    try {
      await _cancelSubscriptions();
      _streamErrors.clear();
      if (_disposed) return;
      _relay();
      await _repository.initialize();
      if (_disposed) return;
      final initial = <Future<void>>[];
      void subscribe<T>(Stream<T> stream, void Function(T) apply) {
        final ready = Completer<void>();
        final token = Object();
        initial.add(ready.future);
        _subscriptions.add(
          stream.listen(
            (value) {
              if (_disposed) return;
              apply(value);
              // 只清除此订阅的错误，不能掩盖另一个尚未恢复的查询。
              _streamErrors.remove(token);
              if (!ready.isCompleted) ready.complete();
              _relay();
            },
            onError: (Object error, StackTrace stack) {
              if (_disposed) return;
              _streamErrors.add(token);
              if (!ready.isCompleted) ready.complete();
              _relay();
            },
            onDone: () {
              if (_disposed || ready.isCompleted) return;
              _streamErrors.add(token);
              ready.complete();
              _relay();
            },
          ),
        );
      }

      subscribe(_repository.watchFileCount(), (value) => _totalFiles = value);
      subscribe(
        _repository.watchTitles(recent: true, limit: 15),
        (value) => _recentlyAddedContent = List.unmodifiable(value),
      );
      subscribe(
        _repository.watchContinueWatching(limit: 15),
        (value) => _continueWatchingItems = List.unmodifiable(value),
      );
      subscribe(_repository.watchHero(), (value) => _hero = value);
      // 退出时不等待永不返回首条数据的流；正常加载仍等待全部首页投影。
      await Future.any([Future.wait(initial), _stopping.future]);
    } catch (error) {
      _loadError = AppFailure.contentLoad;
      await _cancelSubscriptions();
    } finally {
      _initialized = true;
      _relay();
    }
  }

  Stream<List<LibraryItem>> watchTitles({
    LibraryTitleKind? kind,
    String query = '',
    bool recent = false,
    int limit = 100,
  }) => _repository.watchTitles(kind: kind, query: query, recent: recent, limit: limit);

  Stream<LibraryItem?> watchDetail(LibraryItem item) => _repository.watchDetail(item);

  Stream<List<MediaFile>> watchVersions(LibraryItem item) => _repository.watchVersions(item);

  Stream<List<MediaCardVO>> watchFavorites({String query = '', int limit = 100}) =>
      _repository.watchFavorites(query: query, limit: limit);

  Stream<List<MediaCardVO>> watchContinueWatching({int limit = 100}) => _repository.watchContinueWatching(limit: limit);

  Future<List<MediaFile>> getVersions(LibraryItem item) => _repository.getVersions(item);

  Future<List<MediaFile>> getPlaybackQueue(MediaFile file) => _repository.getPlaybackQueue(file);

  Future<MediaFile?> getEpisodeFile(String episodeKey) => _repository.getEpisodeFile(episodeKey);

  Future<MediaSourceScanSummary?> scanMediaSources() => _sync.scanEnabledMediaSources();

  Future<bool> setFavorite(LibraryItem item, {required bool isFavorite}) =>
      _repository.setFavorite(item, isFavorite: isFavorite);

  Future<void> clearLibrary() async {
    await _repository.clearLibrary();
    _sync.reset();
  }

  void _relay() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    beginShutdown();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _sync
      ..removeListener(_relay)
      ..dispose();
    super.dispose();
  }
}
