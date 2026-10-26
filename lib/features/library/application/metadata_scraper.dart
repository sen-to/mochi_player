import 'package:logger/logger.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/features/library/application/metadata_match_resolver.dart';
import 'package:mochi_player/features/library/application/metadata_repository.dart';
import 'package:mochi_player/features/library/application/metadata_source.dart';
import 'package:mochi_player/features/library/application/scrape_candidate.dart';
import 'package:mochi_player/features/library/application/scrape_plan.dart';
import 'package:mochi_player/features/library/application/scrape_result.dart';

/// Coordinates bounded metadata matching and atomic imports through application contracts.
class MetadataScraper {
  final MetadataMatchResolver _matchResolver;
  final MetadataRepository _repository;
  final Logger _logger;

  MetadataScraper({required MetadataMatchResolver matchResolver, required MetadataRepository repository})
    : _matchResolver = matchResolver,
      _repository = repository,
      _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  /// 批量刮削文件
  /// 自动区分电影和剧集，处理并发和去重
  Future<ScrapeResult> scrapeBatch(
    List<MediaFile> allFiles, {
    ScrapeProgressCallback? onProgress,
    bool Function()? shouldStop,
  }) async {
    final result = ScrapeResult();
    if (!_matchResolver.isConfigured) {
      _logger.w('⚠️ 未配置 TMDB API Key，跳过元数据刮削');
      return result;
    }

    final movieFiles = <MediaFile>[];
    final tvFiles = <MediaFile>[];
    // The database supplies only files needing metadata; do not reload metadata tables.
    for (final file in allFiles) {
      if (file.mediaType == MediaType.movie) movieFiles.add(file);
      if (file.mediaType == MediaType.episode) tvFiles.add(file);
    }

    final tvGroups = <String, _TVShowScrapeGroup>{};
    for (final file in tvFiles) {
      final key = _buildTVGroupKey(file);
      tvGroups.putIfAbsent(key, () => _TVShowScrapeGroup(file.parsedTitle)).add(file);
    }

    final totalCount = movieFiles.length + tvFiles.length;
    var completedCount = 0;

    _logger.i('🎬 批量刮削开始: 电影 ${movieFiles.length} 个, 剧集文件 ${tvFiles.length} 个');

    // Publish the real workload before the first network request. The UI used
    // to initialise progress with the entire catalog size, even though most
    // files were filtered out because their metadata already existed.
    await onProgress?.call(
      ScrapeProgress(completed: 0, total: totalCount, successCount: 0, failCount: 0, currentTitle: ''),
    );

    // Process movies independently; TV files share one lookup per show.
    await _runWithConcurrency(
      movieFiles,
      (file) async {
        await _scrapeMovieSingle(file, result);
        completedCount++;
        await onProgress?.call(
          ScrapeProgress(
            completed: completedCount,
            total: totalCount,
            successCount: result.successCount,
            failCount: result.failCount,
            currentTitle: file.parsedTitle,
          ),
        );
      },
      5,
      shouldStop: shouldStop,
    );

    await _runWithConcurrency(
      tvGroups.values.toList(),
      (group) async {
        await _scrapeTVShowGroup(group.title, group.files, result);
        completedCount += group.files.length;
        await onProgress?.call(
          ScrapeProgress(
            completed: completedCount,
            total: totalCount,
            successCount: result.successCount,
            failCount: result.failCount,
            currentTitle: group.title,
          ),
        );
      },
      5,
      shouldStop: shouldStop,
    );

    _logger.i('✅ 批量刮削完成: 新增电影 ${result.newMovieCount} 部, 新增剧集 ${result.newTVShowCount} 部');
    return result;
  }

  bool get isConfigured => _matchResolver.isConfigured;

  // ===== 电影处理 =====

  Future<void> _scrapeMovieSingle(MediaFile file, ScrapeResult result) async {
    final candidate = ScrapeCandidate.fromMediaFile(file);
    try {
      final metadata = (await _matchResolver.resolveMovie(candidate)).metadata;

      if (metadata == null) {
        _logger.w(
          '⚠️ 刮削失败（电影）：未得到可导入的 TMDB 详情\n'
          '${_describeCandidate(candidate)}',
        );
        await _repository.markUnmatched([file]);
        result.failCount++;
        return;
      }

      if (await _repository.importMovie(metadata, file)) {
        result.newMovieCount++;
      }
      result.successCount++;
      return;
    } catch (e) {
      if (e is MetadataRequestFailure) result.requestFailures.add(e);
      _logger.e(
        '❌ 刮削电影出错: $e\n'
        '${_describeCandidate(candidate)}',
      );
      result.failCount++;
      return;
    }
  }

  // ===== 剧集处理 =====

  Future<void> _scrapeTVShowGroup(String showTitle, List<MediaFile> files, ScrapeResult result) async {
    final matchedKeys = <String>{};
    try {
      // Any episode-specific association is stronger evidence than the first
      // file's title. Otherwise the first file represents the group's parsed
      // show title and year.
      final candidates = files.map(ScrapeCandidate.fromMediaFile).toList(growable: false);
      final resolverCandidate = candidates.firstWhere(
        (candidate) => candidate.tvShowTmdbId != null,
        orElse: () => candidates.first,
      );
      final metadata = (await _matchResolver.resolveTVShow(resolverCandidate)).metadata;

      if (metadata == null) {
        _logger.w(
          '⚠️ 刮削失败（剧集）：未得到可导入的 TMDB 剧集详情\n'
          '分组标题: "$showTitle"\n'
          '${_describeCandidate(resolverCandidate)}\n'
          '分组文件（${files.length}）：\n${_describeFiles(files)}',
        );
        await _repository.markUnmatched(files);
        return;
      }

      if (await _repository.importTVShow(metadata)) {
        result.newTVShowCount++;
      }

      final seasonNumbers = files.map((f) => f.parsedSeason).whereType<int>().toSet();

      final failedKeys = <String>{};
      for (final seasonNum in seasonNumbers) {
        final seasonFiles = files.where((f) => f.parsedSeason == seasonNum).toList();
        try {
          matchedKeys.addAll(await _scrapeSeasonAndEpisodes(metadata.tmdbId, seasonNum, seasonFiles));
        } on MetadataRequestFailure catch (failure) {
          result.requestFailures.add(failure);
          failedKeys.addAll(seasonFiles.map((file) => file.storageKey));
          _logger.w('获取季详情失败: $failure');
        }
      }

      // A file only becomes confirmed when its exact episode has been found.
      final unmatchedFileCount = files.length - matchedKeys.length - failedKeys.length;
      if (unmatchedFileCount > 0) {
        final unmatchedFiles = files
            .where((file) => !matchedKeys.contains(file.storageKey) && !failedKeys.contains(file.storageKey))
            .toList(growable: false);
        await _repository.markUnmatched(unmatchedFiles);
        _logger.w(
          '⚠️ 剧集单集匹配不完整\n'
          '剧名: "$showTitle"，TMDB 剧集 ID: ${metadata.tmdbId}\n'
          '未匹配: $unmatchedFileCount / ${files.length}\n'
          '未匹配文件：\n${_describeFiles(unmatchedFiles)}',
        );
      }
      return;
    } catch (e) {
      if (e is MetadataRequestFailure) result.requestFailures.add(e);
      _logger.e(
        '❌ 刮削剧集出错: $e\n'
        '分组标题: "$showTitle"\n'
        '分组文件（${files.length}）：\n${_describeFiles(files)}',
      );
      return;
    } finally {
      // Count each file once, including when later persistence fails after a
      // previous season has already committed successfully.
      result.successCount += matchedKeys.length;
      result.failCount += files.length - matchedKeys.length;
    }
  }

  Future<Set<String>> _scrapeSeasonAndEpisodes(String showTmdbId, int seasonNum, List<MediaFile> seasonFiles) async {
    final season = await _matchResolver.fetchSeason(showTmdbId, seasonNum);
    if (season == null) return {};

    return _repository.importSeasonEpisodes(season, showTmdbId, seasonFiles);
  }

  // ===== 辅助方法 =====

  String _buildTVGroupKey(MediaFile file) {
    final showTmdbId = ScrapeCandidate.fromMediaFile(file).numericExplicitTmdbId ?? file.tvShowTmdbId;
    if (showTmdbId != null) return 'tmdb:$showTmdbId';

    final titleKey = _normalizeGroupKey(file.parsedTitle);
    final yearKey = file.parsedYear?.toString() ?? '';
    return 'title:$titleKey:$yearKey';
  }

  String _normalizeGroupKey(String title) {
    final normalized = title.toLowerCase().replaceAll(RegExp(r'[\s._\-:：，。/\\\(\)\[\]【】]+'), '');
    return normalized.isEmpty ? title.trim().toLowerCase() : normalized;
  }

  String _describeCandidate(ScrapeCandidate candidate) {
    final file = candidate.file;
    final type = candidate.isMovie
        ? '电影'
        : candidate.isEpisode
        ? '剧集'
        : '未知';
    return [
      '文件: ${file.fileName}',
      '路径: ${file.path}',
      '解析: 类型=$type，标题="${candidate.title}"，年份=${candidate.year ?? '无'}，'
          '季=${candidate.seasonNumber ?? '无'}，集=${candidate.episodeNumber ?? '无'}',
      '已有 ID: 显式=${candidate.explicitTmdbId ?? '无'}，电影=${candidate.movieTmdbId ?? '无'}，'
          '剧集=${candidate.tvShowTmdbId ?? '无'}，单集=${candidate.episodeKey ?? '无'}',
      '搜索计划: ${_describeSearchPlan(candidate)}',
    ].join('\n');
  }

  String _describeSearchPlan(ScrapeCandidate candidate) {
    final attempts = const ScrapePlanFactory().createTitleSearchPlan(candidate).attempts;
    if (attempts.isEmpty) return '无（解析标题为空）';
    return attempts.map((attempt) => 'query="${attempt.query}"，year=${attempt.year ?? '无'}').join(' → ');
  }

  String _describeFiles(Iterable<MediaFile> files) => files
      .map(
        (file) =>
            '- ${file.fileName} | 标题="${file.parsedTitle}" | '
            'S${file.parsedSeason ?? '?'}E${file.parsedEpisode ?? '?'} | ${file.path}',
      )
      .join('\n');

  Future<void> _runWithConcurrency<T>(
    List<T> tasks,
    Future<void> Function(T) action,
    int maxConcurrent, {
    bool Function()? shouldStop,
  }) async {
    if (tasks.isEmpty) return;

    final workerCount = tasks.length < maxConcurrent ? tasks.length : maxConcurrent;
    var nextIndex = 0;

    Future<void> runWorker() async {
      while (nextIndex < tasks.length && shouldStop?.call() != true) {
        final item = tasks[nextIndex];
        nextIndex++;
        await action(item);
      }
    }

    await Future.wait(List.generate(workerCount, (_) => runWorker()));
  }
}

class _TVShowScrapeGroup {
  String title;
  final List<MediaFile> files = [];

  _TVShowScrapeGroup(this.title);

  void add(MediaFile file) {
    files.add(file);
    if (_isBetterTitle(file.parsedTitle, title)) {
      title = file.parsedTitle;
    }
  }

  bool _isBetterTitle(String candidate, String current) {
    final candidateText = candidate.trim();
    final currentText = current.trim();
    if (candidateText.isEmpty) return false;
    if (currentText.isEmpty) return true;
    if (int.tryParse(currentText) != null && int.tryParse(candidateText) == null) {
      return true;
    }
    return candidateText.length > currentText.length;
  }
}
