import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/app_failure.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/domain/media/season_metadata.dart';
import 'package:mochi_player/features/library/application/metadata_match_resolver.dart';
import 'package:mochi_player/features/library/application/metadata_scraper.dart';
import 'package:mochi_player/features/library/application/metadata_source.dart';
import 'package:mochi_player/features/library/application/scrape_result.dart';

import '../../../support/library_sync_fakes.dart';

void main() {
  late FakeMetadataSource source;
  late FakeMetadataRepository repository;
  late MetadataScraper scraper;
  setUp(() {
    source = FakeMetadataSource();
    repository = FakeMetadataRepository();
    scraper = MetadataScraper(
      repository: repository,
      matchResolver: MetadataMatchResolver(source: source, repository: repository),
    );
  });

  test('unconfigured sources do not produce lookups or persistence writes', () async {
    source.isConfigured = false;
    final result = await scraper.scrapeBatch([libraryFile('/movie')]);
    expect(result.successCount, 0);
    expect(result.failCount, 0);
    expect(source.calls, isEmpty);
    expect(repository.unmatched, isEmpty);
  });

  test('successful, unmatched and request-failed movies have distinct outcomes', () async {
    const failure = MetadataRequestFailure(
      userFailure: AppFailure.tmdbRateLimited,
      isRetryable: true,
      statusCode: 429,
      retryAfter: Duration(seconds: 30),
    );
    source.onSearchMovie = (title, _) async => switch (title) {
      'Found' => const Movie(tmdbId: '1', title: 'Found'),
      'Failed' => throw failure,
      _ => null,
    };
    final result = await scraper.scrapeBatch([
      libraryFile('/found').copyWith(parsedTitle: 'Found'),
      libraryFile('/missing').copyWith(parsedTitle: 'Missing'),
      libraryFile('/failed').copyWith(parsedTitle: 'Failed'),
    ]);
    expect(result.successCount, 1);
    expect(result.failCount, 2);
    expect(result.newMovieCount, 1);
    expect(result.requestFailures, [same(failure)]);
    expect(repository.importedMovies.single.path, '/found');
    expect(repository.unmatched.single.path, '/missing');
  });

  test('show lookup is shared, and only genuinely missing episodes are marked unmatched', () async {
    source.onSearchTVShow = (_, _) async => const TVShow(tmdbId: '1', title: 'Show');
    source.onSeason = (id, season) async {
      if (season == 2) throw const MetadataRequestFailure(userFailure: AppFailure.tmdbNetwork, isRetryable: true);
      if (season == 3) return null;
      return SeasonMetadata(
        season: Season(tvShowTmdbId: id, seasonNumber: season, title: 'Season'),
        episodes: [Episode(tvShowTmdbId: id, seasonNumber: season, episodeNumber: 1, title: 'Episode')],
      );
    };
    final result = await scraper.scrapeBatch([
      libraryFile('/found', season: 1, episode: 1),
      libraryFile('/missingEpisode', season: 1, episode: 2),
      libraryFile('/failedSeason', season: 2, episode: 1),
      libraryFile('/missingSeason', season: 3, episode: 1),
    ]);
    expect(result.successCount, 1);
    expect(result.failCount, 3);
    expect(result.requestFailures.single.userFailure, AppFailure.tmdbNetwork);
    expect(repository.importedEpisodes, ['local:/found']);
    expect(repository.unmatched.map((file) => file.path), ['/missingEpisode', '/missingSeason']);
    expect(source.calls, ['searchShow:Example:null', 'season:1:1', 'season:1:2', 'season:1:3']);
  });

  for (final failDuringImport in [true, false]) {
    test('partial persistence failure counts each episode once (import: $failDuringImport)', () async {
      source.onSearchTVShow = (_, _) async => const TVShow(tmdbId: '1', title: 'Show');
      source.onSeason = (id, season) async => SeasonMetadata(
        season: Season(tvShowTmdbId: id, seasonNumber: season, title: 'Season'),
        episodes: [Episode(tvShowTmdbId: id, seasonNumber: season, episodeNumber: 1, title: 'Episode')],
      );
      if (failDuringImport) {
        repository.onImportSeason = (metadata) async {
          if (metadata.season.seasonNumber == 2) throw StateError('import failed');
        };
      } else {
        repository.onMarkUnmatched = (_) async => throw StateError('match update failed');
      }
      final result = await scraper.scrapeBatch([
        libraryFile('/found', season: 1, episode: 1),
        libraryFile('/failed', season: failDuringImport ? 2 : 1, episode: failDuringImport ? 1 : 2),
      ]);
      expect(repository.importedEpisodes, ['local:/found']);
      expect(repository.unmatched, isEmpty);
      expect(result.successCount, 1);
      expect(result.failCount, 1);
      expect(result.requestFailures, isEmpty);
    });
  }

  test('workers are bounded and stop taking new work after cancellation', () async {
    final started = Completer<void>();
    final release = Completer<void>();
    var active = 0;
    var peak = 0;
    var stopping = false;
    source.onSearchMovie = (_, _) async {
      active++;
      if (active > peak) peak = active;
      if (active == 5) started.complete();
      await release.future;
      active--;
      return const Movie(tmdbId: '1', title: 'Found');
    };
    final progress = <ScrapeProgress>[];
    final task = scraper.scrapeBatch(
      [for (var i = 0; i < 12; i++) libraryFile('/$i')],
      shouldStop: () => stopping,
      onProgress: (value) async => progress.add(value),
    );
    await started.future;
    expect(source.calls, hasLength(5));
    stopping = true;
    release.complete();
    final result = await task;
    expect(peak, 5);
    expect(result.successCount, 5);
    expect(result.failCount, 0);
    expect(source.calls, hasLength(5));
    expect(progress.first.completed, 0);
    expect(progress.first.total, 12);
    expect(progress.last.completed, 5);
  });
}
