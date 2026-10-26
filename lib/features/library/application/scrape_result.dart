import 'package:mochi_player/features/library/application/metadata_source.dart';

/// Counts completed file outcomes; request failures never imply an unmatched file.
class ScrapeResult {
  int newMovieCount = 0;
  int newTVShowCount = 0;
  int successCount = 0;
  int failCount = 0;
  final List<MetadataRequestFailure> requestFailures = [];
}

class ScrapeProgress {
  final int completed;
  final int total;
  final int successCount;
  final int failCount;
  final String currentTitle;

  const ScrapeProgress({
    required this.completed,
    required this.total,
    required this.successCount,
    required this.failCount,
    required this.currentTitle,
  });
}

typedef ScrapeProgressCallback = Future<void> Function(ScrapeProgress progress);
