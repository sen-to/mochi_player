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

  void beginShutdown() {
    _disposed = true;
    _sync.beginShutdown();
  }

  Future<void> shutdown() async {
    beginShutdown();
    await _loading;
    await Future.wait(_subscriptions.map((subscription) => subscription.cancel()));
    _subscriptions.clear();
    await _sync.shutdown();
  }

  AppFailure? _loadError;
  int totalFiles = 0;
  List<LibraryItem> recentlyAddedContent = const [];
  List<MediaCardVO> continueWatchingItems = const [];
  LibraryItem? _hero;

  bool get isLoading => !_initialized || _sync.isLoading;

  AppFailure? get error => _loadError ?? _sync.error;

  double? get scrapeProgress => _sync.scrapeProgress;

  LibraryActivity? get libraryActivity => _sync.activity;

  bool get hasLibraryContent => recentlyAddedContent.isNotEmpty || continueWatchingItems.isNotEmpty;

  LibraryItem? get heroItem => _hero;

  Future<void> loadFromDatabase() => _loading ??= _load();

  Future<void> _load() async {
    try {
      await _repository.initialize();
      if (_disposed) return;
      final initial = <Future<void>>[];
      void subscribe<T>(Stream<T> stream, void Function(T) apply) {
        final ready = Completer<void>();
        initial.add(ready.future);
        _subscriptions.add(
          stream.listen(
            (value) {
              apply(value);
              if (!ready.isCompleted) ready.complete();
              _relay();
            },
            onError: (Object error, StackTrace stack) {
              _loadError = AppFailure.contentLoad;
              if (!ready.isCompleted) ready.completeError(error, stack);
              _relay();
            },
          ),
        );
      }

      subscribe(_repository.watchFileCount(), (value) => totalFiles = value);
      subscribe(_repository.watchTitles(recent: true, limit: 15), (value) => recentlyAddedContent = value);
      subscribe(
        _repository.watchContinueWatching(limit: 15),
        (value) => continueWatchingItems = List.unmodifiable(value),
      );
      subscribe(_repository.watchHero(), (value) => _hero = value);
      await Future.wait(initial);
    } catch (error) {
      _loadError = AppFailure.contentLoad;
    } finally {
      _initialized = true;
      _relay();
    }
  }

  Stream<List<LibraryItem>> watchTitles({String? kind, String query = '', bool recent = false, int limit = 100}) =>
      _repository.watchTitles(kind: kind, query: query, recent: recent, limit: limit);

  Stream<LibraryItem?> watchDetail(LibraryItem item) => _repository.watchDetail(item);

  Stream<List<MediaFile>> watchVersions(LibraryItem item) => _repository.watchVersions(item);

  Stream<List<MediaCardVO>> watchFavorites({String query = '', int limit = 100}) =>
      _repository.watchFavorites(query: query, limit: limit);

  Stream<List<MediaCardVO>> watchContinueWatching({int limit = 100}) => _repository.watchContinueWatching(limit: limit);

  Future<List<MediaFile>> getVersions(LibraryItem item) => _repository.getVersions(item);

  Future<List<MediaFile>> getPlaybackQueue(MediaFile file) => _repository.getPlaybackQueue(file);

  Future<MediaFile?> getEpisodeFile(String id) => _repository.getEpisodeFile(id);

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
    _disposed = true;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _sync
      ..removeListener(_relay)
      ..dispose();
    super.dispose();
  }
}
