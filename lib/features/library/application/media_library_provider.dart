import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/infrastructure/database/database_service.dart';
import 'package:mochi_player/core/infrastructure/database/entities/entities.dart' as entity;
import 'package:mochi_player/core/infrastructure/database/media_entity_mapper.dart';
import 'package:mochi_player/features/library/application/library_search_matcher.dart';
import 'package:mochi_player/features/library/application/library_sync_controller.dart';
import 'package:mochi_player/features/library/application/media_card_view_data.dart';
import 'package:mochi_player/features/library/application/media_library_catalog.dart';
import 'package:mochi_player/features/library/application/media_library_queries.dart';

/// UI-facing facade for the local media library.
///
/// Persistent catalog data has one owner, read projections are delegated to
/// [MediaLibraryQueries], and scan/scrape workflows are delegated to
/// [LibrarySyncController].
class MediaLibraryProvider extends ChangeNotifier {
  MediaLibraryProvider({DatabaseService? database}) : _db = database ?? DatabaseService() {
    _queries = MediaLibraryQueries(_catalog);
    _syncController = LibrarySyncController(catalog: _catalog, database: _db)..addListener(_relaySyncChanges);
  }

  final DatabaseService _db;
  final MediaLibraryCatalog _catalog = MediaLibraryCatalog();
  final _logger = Logger(printer: PrettyPrinter(methodCount: 0));
  late final MediaLibraryQueries _queries;
  late final LibrarySyncController _syncController;

  List<MediaFile> get mediaFiles => _queries.mediaFiles;

  List<Movie> get movies => _queries.movies;

  List<TVShow> get tvShows => _queries.tvShows;

  List<MediaFile> get uncategorized => _queries.uncategorized;

  List<MediaCardViewData> get continueWatchingItems => _queries.continueWatchingItems;

  List<MediaCardViewData> get favoriteItems => _queries.favoriteItems;

  List<LibraryItem> get recentlyAddedContent => _queries.recentlyAddedContent;

  bool get isLoading => _syncController.isLoading;

  String? get error => _syncController.error;

  double? get scrapeProgress => _syncController.scrapeProgress;

  String? get libraryActivityMessage => _syncController.activityMessage;

  int get mediaCatalogRevision => _catalog.mediaCatalogRevision;

  int get metadataRevision => _catalog.metadataRevision;

  int get watchProgressRevision => _catalog.watchProgressRevision;

  int get favoriteRevision => _catalog.favoriteRevision;

  int get totalFiles => _catalog.mediaFiles.length;

  bool get hasLibraryContent => _queries.hasContent;

  List<MediaFile> getVersions(String tmdbId) => _queries.getVersions(tmdbId);

  List<MediaFile> getPlaybackQueue(MediaFile currentFile) => _queries.getPlaybackQueue(currentFile);

  LibraryItem? getRandomHeroItem() => _queries.getRandomHeroItem();

  List<LibraryItem> searchLibrary(String query) =>
      LibrarySearchMatcher.libraryItems<LibraryItem>([...movies, ...tvShows], query);

  List<Movie> searchMovies(String query) => LibrarySearchMatcher.libraryItems(movies, query);

  List<TVShow> searchTVShows(String query) => LibrarySearchMatcher.libraryItems(tvShows, query);

  List<MediaCardViewData> searchFavorites(String query) => LibrarySearchMatcher.mediaCards(favoriteItems, query);

  Future<void> loadFromDatabase() => _syncController.loadFromDatabase();

  /// Refreshes only files whose playback state changed in a separate player
  /// window. Metadata is unchanged, while watch state and the
  /// continue-watching order may have changed.
  Future<void> refreshPlaybackState(Iterable<({String sourceId, String path})> changedMedia) async {
    var didUpdate = false;
    for (final key in changedMedia.toSet()) {
      final latest = await _db.getMediaFile(key.sourceId, key.path);
      if (latest == null) continue;
      final index = _catalog.mediaFiles.indexWhere((file) => file.sourceId == key.sourceId && file.path == key.path);
      if (index < 0) continue;
      _catalog.mediaFiles[index] = latest;
      didUpdate = true;
    }
    if (!didUpdate) return;
    _catalog.recountContinueWatching();
    _catalog.markWatchProgressChanged();
    notifyListeners();
  }

  Future<void> refreshLibraryMetadata() => _syncController.refreshLibraryMetadata();

  Future<MediaSourceScanSummary?> scanMediaSources() => _syncController.scanEnabledMediaSources();

  Future<void> updateProgress(MediaFile file, int position, {int? duration}) async {
    final entity = _findMediaFileEntity(file);
    if (entity == null) {
      _logger.d('跳过临时文件播放进度: ${file.path}');
      return;
    }

    await _db.updateProgress(entity, position, duration: duration);
    _catalog.recountContinueWatching();
    _catalog.markWatchProgressChanged();
    notifyListeners();
  }

  /// Gets the latest persisted state instead of relying on a stale UI model.
  Future<MediaFile?> getLatestMediaFile(MediaFile file) async {
    entity.MediaFileEntity? latest;
    if (file.path.isNotEmpty) {
      latest = await _db.getMediaFile(file.sourceId, file.path);
    }
    latest ??= _findMediaFileEntity(file);
    if (latest == null) return null;

    final index = _catalog.mediaFiles.indexWhere(
      (item) => item.id == latest!.id || (item.sourceId == file.sourceId && item.path == file.path),
    );
    if (index >= 0) {
      _catalog.mediaFiles[index] = latest;
    }
    return MediaEntityMapper.toMediaFile(latest);
  }

  bool isFavorite(String tmdbId) => getVersions(tmdbId).any((file) => file.isFavorite);

  /// Applies one favorite state to every physical version of a title.
  Future<bool> setFavorite(String tmdbId, {required bool isFavorite}) async {
    final matchingFiles = _catalog.mediaFiles
        .where((file) => file.movieTmdbId == tmdbId || file.tvShowTmdbId == tmdbId)
        .toList();
    if (matchingFiles.isEmpty) return false;

    final changedFiles = matchingFiles.where((file) => file.isFavorite != isFavorite).toList();
    if (changedFiles.isNotEmpty) {
      await _db.setFavorite(changedFiles, isFavorite: isFavorite);
      _catalog.markFavoriteChanged();
      notifyListeners();
    }
    return true;
  }

  Future<void> clearLibrary() async {
    await _db.clearAll();
    _catalog.clear();
    _syncController.reset();
  }

  /// Removes in-memory library records already deleted for one storage source.
  void removeSourceMediaFromCatalog(String sourceId) {
    final removed = _catalog.mediaFiles.where((file) => file.sourceId == sourceId).map((file) => file.id).toSet();
    if (removed.isEmpty) return;

    _catalog.mediaFiles.removeWhere((file) => removed.contains(file.id));
    _catalog.recountContinueWatching();
    _catalog.markAllLibraryContentChanged();
    notifyListeners();
  }

  entity.MediaFileEntity? _findMediaFileEntity(MediaFile file) {
    for (final entity in _catalog.mediaFiles) {
      if (entity.id == file.id || (entity.sourceId == file.sourceId && entity.path == file.path)) {
        return entity;
      }
    }
    return null;
  }

  void _relaySyncChanges() => notifyListeners();

  @override
  void dispose() {
    _syncController
      ..removeListener(_relaySyncChanges)
      ..dispose();
    super.dispose();
  }
}
