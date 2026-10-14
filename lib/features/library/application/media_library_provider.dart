import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mochi_player/core/domain/app_failure.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/infrastructure/database/database_service.dart';
import 'package:mochi_player/features/library/application/library_sync_controller.dart';
import 'package:mochi_player/features/library/application/media_card_view_data.dart';
import 'package:mochi_player/features/library/infrastructure/library_repository.dart';

/// UI facade. SQLite owns persisted records; only bounded home projections are retained.
class MediaLibraryProvider extends ChangeNotifier {
  MediaLibraryProvider({DatabaseService? database}) : _db = database ?? DatabaseService() {
    repository = LibraryRepository(_db);
    _sync = LibrarySyncController(database: _db)..addListener(_relay);
  }

  final DatabaseService _db;
  late final LibraryRepository repository;
  late final LibrarySyncController _sync;
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
  List<MediaCardViewData> continueWatchingItems = const [];
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
      await _db.init();
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

      subscribe(repository.watchFileCount(), (value) => totalFiles = value);
      subscribe(repository.watchTitles(recent: true, limit: 15), (value) => recentlyAddedContent = value);
      subscribe(
        repository.watchContinueWatching(limit: 15),
        (value) => continueWatchingItems = List.unmodifiable(value),
      );
      subscribe(repository.watchHero(), (value) => _hero = value);
      await Future.wait(initial);
    } catch (error) {
      _loadError = AppFailure.contentLoad;
    } finally {
      _initialized = true;
      _relay();
    }
  }

  Future<List<MediaFile>> getVersions(LibraryItem item) => repository.getVersions(item);

  Future<List<MediaFile>> getPlaybackQueue(MediaFile file) => repository.getPlaybackQueue(file);

  Future<MediaFile?> getEpisodeFile(String id) => repository.getEpisodeFile(id);

  Future<MediaFile?> getLatestMediaFile(MediaFile file) => _db.getMediaFile(file.sourceId, file.path);

  Future<MediaSourceScanSummary?> scanMediaSources() => _sync.scanEnabledMediaSources();

  Future<void> updateProgress(MediaFile file, int position, {int? duration}) async {
    final latest = await getLatestMediaFile(file);
    if (latest != null) await _db.updateProgress(latest, position, duration: duration);
  }

  Future<bool> setFavorite(LibraryItem item, {required bool isFavorite}) => _db.setTitleFavorite(item, isFavorite);

  Future<void> clearLibrary() async {
    await _db.clearLibrary();
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
