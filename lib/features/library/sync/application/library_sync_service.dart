// 【业务编排】协调启用来源扫描、分批入库、失效清理与元数据刮削。
// 通过契约访问存储和数据库；不完整扫描不删除旧索引。

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:mochi_player/core/domain/app_failure.dart';
import 'package:mochi_player/core/domain/media/library_activity.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/features/library/metadata/application/metadata_scraper.dart';
import 'package:mochi_player/features/library/sync/application/library_source_scanner.dart';
import 'package:mochi_player/features/library/sync/application/library_sync_repository.dart';

/// 协调来源扫描、索引清理及可选元数据刮削。
class LibrarySyncService extends ChangeNotifier {
  LibrarySyncService({
    required LibrarySyncRepository repository,
    required LibrarySourceScanner sourceScanner,
    required MetadataScraper metadataScraper,
  }) : _repository = repository,
       _sourceScanner = sourceScanner,
       _metadataScraper = metadataScraper;

  final LibrarySyncRepository _repository;
  final LibrarySourceScanner _sourceScanner;
  final MetadataScraper _metadataScraper;
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

  /// 扫描所有启用来源并更新本地文件索引；扫描不需要 TMDB 密钥，发现文件后的元数据刮削为独立可选步骤。
  Future<MediaSourceScanSummary?> scanEnabledMediaSources() {
    if (_shuttingDown || _activeScan != null || isLoading) return Future.value(null);
    return _activeScan = _scanEnabledMediaSources().whenComplete(() => _activeScan = null);
  }

  Future<MediaSourceScanSummary?> _scanEnabledMediaSources() async {
    _isScanning = true;
    _error = null;
    _scanCompletedSources = 0;
    _scanTotalSources = 0;
    _scanCurrentSource = null;
    _notify();

    try {
      if (_shuttingDown) return null;
      final sources = await _sourceScanner.enabledSources();
      if (_shuttingDown) return null;
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
          final result = await _scanSource(source);
          if (result == null) break;
          discoveredFileCount += result.discoveredCount;
          newFileCount += result.newCount;
          removedFileCount += result.removedCount;
          _logger.i(
            '媒体源 ${source.name} 扫描完成：发现 ${result.discoveredCount} 个视频，'
            '新增 ${result.newCount} 个，移除 ${result.removedCount} 个',
          );
          if (result.hadReadError || result.closeFailed) {
            failedSourceCount++;
            if (result.hadReadError) _logger.w('媒体源 ${source.name} 的扫描不完整，已跳过失效文件清理');
          } else {
            completedSourceCount++;
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
    if (_shuttingDown || !_metadataScraper.isConfigured) return null;
    return _scrapeMetadata();
  }

  void reset() {
    if (_activeScan != null || isLoading) return;
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
    // 刮削器排除已有元数据的文件后确定真实工作量，不能先把整个媒体库都显示为待刮削。
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

  Future<_LibraryScanResult?> _scanSource(StorageSource source) async {
    final scan = await _sourceScanner.open(source);
    _LibraryScanResult? result;
    try {
      // 读取凭据或解析连接期间也可能开始退出。
      if (!_shuttingDown) result = await _scanFilesFromSource(source.id, scan);
    } finally {
      try {
        await scan.close();
      } catch (error) {
        _logger.w('关闭媒体源 ${source.name} 失败: $error');
        if (result == null) rethrow;
        // 关闭失败前已提交的索引变化仍计入结果。
        result = result.withCloseFailure();
      }
    }
    return result;
  }

  Future<_LibraryScanResult> _scanFilesFromSource(String sourceId, LibrarySourceScanSession scanner) async {
    final knownPaths = await _repository.sourcePaths(sourceId);
    var newCount = 0;
    var discoveredCount = 0;
    final scannedPaths = <String>{};
    final pending = <MediaFile>[];
    Future<void> flush() async {
      if (pending.isEmpty) return;
      final batch = List<MediaFile>.unmodifiable(pending);
      pending.clear();
      // 写入失败即中止当前来源，清理阶段不能隐式重试失败批次。
      await _repository.saveScannedFiles(batch);
    }

    // 即使后续目录读取失败，也保存之前成功发现的文件。
    try {
      final files = _shuttingDown ? const Stream<MediaFile>.empty() : scanner.scan();
      await for (final file in files) {
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
        : await _repository.removeMissingFiles(sourceId, scannedPaths);

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
    this.closeFailed = false,
  });

  final int discoveredCount;
  final int newCount;
  final int removedCount;
  final bool hadReadError;
  final bool closeFailed;

  _LibraryScanResult withCloseFailure() => _LibraryScanResult(
    discoveredCount: discoveredCount,
    newCount: newCount,
    removedCount: removedCount,
    hadReadError: hadReadError,
    closeFailed: true,
  );
}

/// 本次全部启用媒体源的扫描结果。
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

  /// 空值表示未尝试元数据刮削，通常因为未配置 TMDB 密钥。
  final int? metadataMatchedCount;
  final int? metadataFailedCount;
}
