import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:mochi_player/core/domain/app_failure.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/infrastructure/database/database_service.dart';
import 'package:mochi_player/core/infrastructure/storage/storage_adapter_registry.dart';
import 'package:mochi_player/features/library/application/storage_sources_service.dart';
import 'package:mochi_player/core/infrastructure/tmdb/tmdb_service.dart';
import 'package:mochi_player/features/library/infrastructure/library_repository.dart';
import 'package:mochi_player/features/library/infrastructure/metadata_scraper.dart';
import 'package:mochi_player/features/library/infrastructure/storage_media_scanner.dart';

/// Coordinates storage scans and TMDB metadata scraping.
class LibrarySyncService extends ChangeNotifier {
  LibrarySyncService({
    required DatabaseService database,
    required LibraryRepository repository,
    required TmdbService tmdbService,
    required MetadataScraper metadataScraper,
    required StorageSourcesService storageSources,
    required StorageAdapterRegistry storageAdapterRegistry,
    required StorageMediaScanner Function(StorageConnection connection) storageScannerFactory,
  }) : _db = database,
       _repository = repository,
       _tmdbService = tmdbService,
       _metadataScraper = metadataScraper,
       _storageSources = storageSources,
       _storageAdapterRegistry = storageAdapterRegistry,
       _storageScannerFactory = storageScannerFactory;

  final DatabaseService _db;
  final LibraryRepository _repository;
  final TmdbService _tmdbService;
  final MetadataScraper _metadataScraper;
  final StorageSourcesService _storageSources;
  final StorageAdapterRegistry _storageAdapterRegistry;
  final StorageMediaScanner Function(StorageConnection connection) _storageScannerFactory;
  final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  bool _shuttingDown = false;
  bool _disposed = false;
  Future<MediaSourceScanSummary?>? _activeScan;

  void beginShutdown() => _shuttingDown = true;

  Future<void> shutdown() async {
    beginShutdown();
    await _activeScan;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    beginShutdown();
    _disposed = true;
    super.dispose();
  }

  bool _isScanning = false;
  bool _isScraping = false;
  AppFailure? _error;
  int _scrapeCompleted = 0;
  int _scrapeTotal = 0;
  int _scrapeSuccessCount = 0;
  int _scrapeFailCount = 0;
  String? _scrapeCurrentTitle;
  int _scanCompletedSources = 0;
  int _scanTotalSources = 0;
  String? _scanCurrentSource;

  bool get isLoading => _isScanning || _isScraping;

  AppFailure? get error => _error;

  double? get scrapeProgress {
    if (!_isScraping || _scrapeTotal <= 0) return null;
    return (_scrapeCompleted / _scrapeTotal).clamp(0.0, 1.0);
  }

  LibraryActivity? get activity {
    if (_isScraping) {
      return LibraryActivity(
        kind: LibraryActivityKind.scraping,
        completed: _scrapeCompleted,
        total: _scrapeTotal,
        success: _scrapeSuccessCount,
        failed: _scrapeFailCount,
        title: _scrapeCurrentTitle ?? '',
      );
    }
    if (_isScanning) {
      return LibraryActivity(
        kind: LibraryActivityKind.scanning,
        completed: _scanCompletedSources,
        total: _scanTotalSources,
        title: _scanCurrentSource ?? '',
      );
    }
    return null;
  }

  /// Scans every enabled media source and updates the local file index.
  ///
  /// This workflow deliberately does not require a TMDB key. Metadata
  /// scraping is a separate optional step after files have been discovered.
  Future<MediaSourceScanSummary?> scanEnabledMediaSources() {
    if (_shuttingDown || isLoading) return Future.value(null);
    return _activeScan = _scanEnabledMediaSources();
  }

  Future<MediaSourceScanSummary?> _scanEnabledMediaSources() async {
    _isScanning = true;
    _error = null;
    _scanCompletedSources = 0;
    _scanTotalSources = 0;
    _scanCurrentSource = null;
    _notify();

    try {
      await _db.init();

      if (_shuttingDown) return null;
      final sources = (await _storageSources.getAll())
          .where((source) => source.enabled && _storageAdapterRegistry.supports(source.type))
          .toList(growable: false);
      if (sources.isEmpty) {
        _error = AppFailure.scanSourceRequired;
        return null;
      }

      _scanTotalSources = sources.length;
      var completedSourceCount = 0;
      var failedSourceCount = 0;
      var discoveredFileCount = 0;
      var newFileCount = 0;
      var removedFileCount = 0;
      for (final source in sources) {
        if (_shuttingDown) break;
        _scanCurrentSource = source.name;
        _notify();
        try {
          final credentials = await _storageSources.readCredentials(source.id);
          final connection = await _storageAdapterRegistry.connect(source, credentials);
          try {
            final result = await _scanFilesFromStorage(connection);
            discoveredFileCount += result.discoveredCount;
            newFileCount += result.newCount;
            removedFileCount += result.removedCount;
            _logger.i(
              '媒体源 ${source.name} 扫描完成：发现 ${result.discoveredCount} 个视频，'
              '新增 ${result.newCount} 个，移除 ${result.removedCount} 个',
            );
            if (result.hadReadError) {
              failedSourceCount++;
              _logger.w('媒体源 ${source.name} 的扫描不完整，已跳过失效文件清理');
            } else {
              completedSourceCount++;
            }
          } finally {
            await connection.close();
          }
        } catch (error) {
          failedSourceCount++;
          _logger.w('扫描媒体源 ${source.name} 失败: $error');
        } finally {
          _scanCompletedSources++;
          _notify();
        }
      }
      _logger.i(
        '全部媒体源扫描完成：启用 ${sources.length} 个，'
        '成功 $completedSourceCount 个，失败 $failedSourceCount 个，'
        '发现 $discoveredFileCount 个视频，新增 $newFileCount 个，'
        '移除 $removedFileCount 个',
      );
      if (_shuttingDown) return null;
      final scrapeResult = await _scrapeScannedMediaFiles();
      return MediaSourceScanSummary(
        enabledSourceCount: sources.length,
        completedSourceCount: completedSourceCount,
        failedSourceCount: failedSourceCount,
        discoveredFileCount: discoveredFileCount,
        newFileCount: newFileCount,
        removedFileCount: removedFileCount,
        metadataMatchedCount: scrapeResult?.successCount,
        metadataFailedCount: scrapeResult?.failCount,
      );
    } catch (error, stackTrace) {
      _logger.e('Media source scan failed', error: error, stackTrace: stackTrace);
      _error = AppFailure.scanFailed;
      return null;
    } finally {
      _isScanning = false;
      _scanCurrentSource = null;
      _notify();
    }
  }

  Future<ScrapeResult?> _scrapeScannedMediaFiles() async {
    if (_shuttingDown || !_tmdbService.isConfigured) return null;
    return _scrapeMetadata();
  }

  void reset() {
    _isScanning = false;
    _isScraping = false;
    _error = null;
    _scrapeCompleted = 0;
    _scrapeTotal = 0;
    _scrapeSuccessCount = 0;
    _scrapeFailCount = 0;
    _scrapeCurrentTitle = null;
    _scanCompletedSources = 0;
    _scanTotalSources = 0;
    _scanCurrentSource = null;
    _notify();
  }

  Future<ScrapeResult?> _scrapeMetadata() async {
    if (_shuttingDown || _isScraping) return null;

    _isScraping = true;
    _scrapeCompleted = 0;
    // The scraper determines the real workload after excluding files that
    // already have persisted metadata. Do not briefly show the full catalog
    // size as if every file were going to be scraped.
    _scrapeTotal = 0;
    _scrapeSuccessCount = 0;
    _scrapeFailCount = 0;
    _scrapeCurrentTitle = null;
    _notify();

    try {
      final result = await _metadataScraper.scrapeBatch(
        await _repository.scrapeCandidates(),
        shouldStop: () => _shuttingDown,
        onProgress: (progress) async {
          _scrapeCompleted = progress.completed;
          _scrapeTotal = progress.total;
          _scrapeSuccessCount = progress.successCount;
          _scrapeFailCount = progress.failCount;
          _scrapeCurrentTitle = progress.currentTitle;

          _notify();
        },
      );
      if (result.requestFailures.isNotEmpty) _error = result.requestFailures.first.userFailure;
      return result;
    } catch (error, stackTrace) {
      _logger.e('刮削失败', error: error, stackTrace: stackTrace);
      _error = AppFailure.scrapeFailed;
      return null;
    } finally {
      _isScraping = false;
      _scrapeCurrentTitle = null;
      _notify();
    }
  }

  Future<_LibraryScanResult> _scanFilesFromStorage(StorageConnection connection) async {
    final scanner = _storageScannerFactory(connection);
    final knownPaths = await _repository.sourcePaths(connection.source.id);
    var newCount = 0;
    var discoveredCount = 0;
    final scannedPaths = <String>{};
    final pending = <MediaFile>[];
    Future<void> flush() async {
      await _db.saveScannedFiles(pending);
      pending.clear();
    }

    // Persist successful discoveries even when a later directory fails.
    try {
      await for (final file in scanner.scan()) {
        if (_shuttingDown) break;
        discoveredCount++;
        if (scannedPaths.add(file.path) && !knownPaths.contains(file.path)) newCount++;
        pending.add(file);
        if (pending.length >= 128) await flush();
      }
    } finally {
      await flush();
    }
    final removedCount = (_shuttingDown || scanner.hadReadError)
        ? 0
        : await _repository.removeMissingFiles(connection.source.id, scannedPaths);

    return _LibraryScanResult(
      discoveredCount: discoveredCount,
      newCount: newCount,
      removedCount: removedCount,
      hadReadError: scanner.hadReadError,
    );
  }
}

class _LibraryScanResult {
  const _LibraryScanResult({
    required this.discoveredCount,
    required this.newCount,
    required this.removedCount,
    required this.hadReadError,
  });

  final int discoveredCount;
  final int newCount;
  final int removedCount;
  final bool hadReadError;
}

/// The outcome of scanning all currently enabled media sources.
class MediaSourceScanSummary {
  const MediaSourceScanSummary({
    required this.enabledSourceCount,
    required this.completedSourceCount,
    required this.failedSourceCount,
    required this.discoveredFileCount,
    required this.newFileCount,
    required this.removedFileCount,
    this.metadataMatchedCount,
    this.metadataFailedCount,
  });

  final int enabledSourceCount;
  final int completedSourceCount;
  final int failedSourceCount;
  final int discoveredFileCount;
  final int newFileCount;
  final int removedFileCount;

  /// Null means metadata scraping was not attempted, typically because the
  /// TMDB API key is not configured.
  final int? metadataMatchedCount;
  final int? metadataFailedCount;
}
