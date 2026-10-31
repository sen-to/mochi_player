// 【行为测试】验证按受限并发匹配电影与剧集，并统计文件级结果。
// 测试对象的职责边界：匹配规则交给 MetadataMatcher，原子导入交给持久化契约。

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/data/database/app_database.dart';
import 'package:mochi_player/core/data/database/sqlite_setup.dart';
import 'package:mochi_player/core/data/tmdb/tmdb_api.dart';
import 'package:mochi_player/core/domain/app_failure.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/domain/media/season_metadata.dart';
import 'package:mochi_player/features/library/metadata/application/metadata_matcher.dart';
import 'package:mochi_player/features/library/metadata/application/metadata_scraper.dart';
import 'package:mochi_player/features/library/metadata/application/scrape_candidate_mapper.dart';
import 'package:mochi_player/features/library/metadata/data/metadata_repository_impl.dart';
import 'package:mochi_player/features/library/metadata/data/tmdb_metadata_source.dart';
import 'package:mochi_player/features/library/metadata/domain/metadata_match.dart';
import 'package:mochi_player/features/library/metadata/domain/scrape_candidate.dart';

import '../../../support/database_fixture.dart';
import '../../../support/tmdb_fixture.dart';

void main() {
  late AppDatabase db;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory(setup: configureSqlite));
    await db.init();
  });
  tearDown(() => db.close());

  for (final status in [401, 429, 503]) {
    test('HTTP $status preserves movie association and user state; a later retry succeeds', () async {
      final file = MediaFile(
        id: 0,
        sourceId: 'nas',
        path: '/movie',
        fileName: 'Movie.mkv',
        parsedTitle: 'Movie',
        parsedYear: 2020,
        mediaType: MediaType.movie,
        explicitTmdbId: '2',
        movieTmdbId: '1',
        metadataMatchStatus: MetadataMatchStatus.confirmed,
        addedAt: DateTime.utc(2026),
      );
      await saveMediaFixture(db, [file]);
      await db.updateProgress(file, 40, duration: 100);
      await db.setTitleFavorite(const Movie(tmdbId: '1', title: 'Movie'), true);
      var failing = true;
      final paths = <String>[];
      final tmdb = tmdbFixture((request, handler) {
        paths.add(request.uri.path);
        handler.resolve(
          Response<dynamic>(
            requestOptions: request,
            statusCode: failing ? status : 200,
            data: {'id': 2, 'title': 'Movie'},
          ),
        );
      });
      final scraper = MetadataScraper(
        repository: MetadataRepositoryImpl(database: db),
        matcher: MetadataMatcher(
          source: TmdbMetadataSource(api: tmdb),
          repository: MetadataRepositoryImpl(database: db),
        ),
      );
      final result = await scraper.scrapeBatch([file]);
      expect(result.failCount, 1);
      expect(result.successCount, 0);
      expect(result.requestFailures.single.statusCode, status);
      expect(paths, ['/3/movie/2']); // A failed request must not trigger title fallback.
      final unchanged = (await db.getMediaFile('nas', '/movie'))!;
      expect(unchanged.movieTmdbId, '1');
      expect(unchanged.metadataMatchStatus, MetadataMatchStatus.confirmed);
      expect(unchanged.position, 40);
      expect(unchanged.isFavorite, isTrue);
      failing = false;
      final retried = await scraper.scrapeBatch([unchanged]);
      expect(retried.successCount, 1);
      expect(retried.requestFailures, isEmpty);
      expect((await db.getMediaFile('nas', '/movie'))!.movieTmdbId, '2');
    });
  }

  test('a missing search endpoint preserves the existing association', () async {
    final file = MediaFile(
      id: 0,
      sourceId: 'nas',
      path: '/movie',
      fileName: 'Movie.mkv',
      parsedTitle: 'Movie',
      mediaType: MediaType.movie,
      explicitTmdbId: '2',
      movieTmdbId: '1',
      metadataMatchStatus: MetadataMatchStatus.confirmed,
      addedAt: DateTime.utc(2026),
    );
    await saveMediaFixture(db, [file]);
    final tmdb = tmdbFixture(
      (request, handler) => handler.resolve(Response<dynamic>(requestOptions: request, statusCode: 404)),
    );
    final result = await MetadataScraper(
      repository: MetadataRepositoryImpl(database: db),
      matcher: MetadataMatcher(
        source: TmdbMetadataSource(api: tmdb),
        repository: MetadataRepositoryImpl(database: db),
      ),
    ).scrapeBatch([file]);
    expect(result.requestFailures.single.statusCode, 404);
    expect(result.failCount, 1);
    final stored = (await db.getMediaFile('nas', file.path))!;
    expect(stored.movieTmdbId, '1');
    expect(stored.metadataMatchStatus, MetadataMatchStatus.confirmed);
  });

  test('a successful empty search still marks a movie unmatched', () async {
    final file = MediaFile(
      id: 0,
      sourceId: 'nas',
      path: '/missing',
      fileName: 'Missing.mkv',
      parsedTitle: 'Missing',
      mediaType: MediaType.movie,
      explicitTmdbId: '2',
      movieTmdbId: '1',
      metadataMatchStatus: MetadataMatchStatus.confirmed,
      addedAt: DateTime.utc(2026),
    );
    await saveMediaFixture(db, [file]);
    final tmdb = tmdbFixture(
      (request, handler) => handler.resolve(
        Response<dynamic>(
          requestOptions: request,
          statusCode: request.uri.path.contains('/search/') ? 200 : 404,
          data: {'results': []},
        ),
      ),
    );
    final result = await MetadataScraper(
      repository: MetadataRepositoryImpl(database: db),
      matcher: MetadataMatcher(
        source: TmdbMetadataSource(api: tmdb),
        repository: MetadataRepositoryImpl(database: db),
      ),
    ).scrapeBatch([file]);
    expect(result.failCount, 1);
    expect(result.requestFailures, isEmpty);
    final stored = (await db.getMediaFile('nas', '/missing'))!;
    expect(stored.movieTmdbId, isNull);
    expect(stored.metadataMatchStatus, MetadataMatchStatus.unmatched);
  });

  test('a failed season retains its old episode while other seasons complete', () async {
    final files = [
      for (var season = 1; season <= 3; season++)
        MediaFile(
          id: 0,
          sourceId: 'nas',
          path: '/season$season',
          fileName: 'S$season.mkv',
          parsedTitle: 'Show',
          parsedSeason: season,
          parsedEpisode: 1,
          mediaType: MediaType.episode,
          explicitTmdbId: '2',
          tvShowTmdbId: '1',
          episodeKey: '1_s${season}e1',
          metadataMatchStatus: MetadataMatchStatus.confirmed,
          addedAt: DateTime.utc(2026),
        ),
    ];
    await saveMediaFixture(db, files);
    final tmdb = tmdbFixture((request, handler) {
      final path = request.uri.path;
      if (path.endsWith('/season/2')) {
        handler.reject(DioException(requestOptions: request, type: DioExceptionType.connectionTimeout));
      } else {
        handler.resolve(
          Response<dynamic>(
            requestOptions: request,
            statusCode: path.endsWith('/season/3') ? 404 : 200,
            data: path.endsWith('/season/1')
                ? {
                    'name': 'Season',
                    'episodes': [
                      {'id': 21, 'episode_number': 1, 'name': 'Episode'},
                    ],
                  }
                : {'id': 2, 'name': 'Show'},
          ),
        );
      }
    });
    final result = await MetadataScraper(
      repository: MetadataRepositoryImpl(database: db),
      matcher: MetadataMatcher(
        source: TmdbMetadataSource(api: tmdb),
        repository: MetadataRepositoryImpl(database: db),
      ),
    ).scrapeBatch(files);
    expect(result.successCount, 1);
    expect(result.failCount, 2);
    expect(result.requestFailures.single.userFailure, AppFailure.tmdbTimeout);
    expect((await db.getMediaFile('nas', '/season1'))!.episodeKey, '2_s1e1');
    final failed = (await db.getMediaFile('nas', '/season2'))!;
    expect(failed.episodeKey, '1_s2e1');
    expect(failed.metadataMatchStatus, MetadataMatchStatus.confirmed);
    final missing = (await db.getMediaFile('nas', '/season3'))!;
    expect(missing.episodeKey, isNull);
    expect(missing.metadataMatchStatus, MetadataMatchStatus.unmatched);
  });

  test('partially matched immutable snapshots do not mark successful episodes unmatched', () async {
    final files = [
      for (var e = 1; e <= 2; e++)
        MediaFile(
          id: 0,
          sourceId: 'nas',
          path: '/$e',
          fileName: '$e.mkv',
          parsedTitle: 'Show',
          parsedSeason: 1,
          parsedEpisode: e,
          mediaType: MediaType.episode,
          tvShowTmdbId: '999',
          episodeKey: '999_s1e$e',
          addedAt: DateTime.utc(2026),
        ),
    ];
    await saveMediaFixture(db, files);
    await db.updateProgress(files.first, 40, duration: 100);
    await db.setTitleFavorite(const TVShow(tmdbId: '999', title: 'Show'), true);
    final result = await MetadataScraper(
      repository: MetadataRepositoryImpl(database: db),
      matcher: _EpisodeResolver(db),
    ).scrapeBatch(files);
    expect(result.successCount, 1);
    expect(result.failCount, 1);
    final first = (await db.getMediaFile('nas', '/1'))!;
    final second = (await db.getMediaFile('nas', '/2'))!;
    expect(first.episodeKey, '123_s1e1');
    expect(first.metadataMatchStatus, MetadataMatchStatus.confirmed);
    expect(first.position, 40);
    expect(first.isFavorite, isTrue);
    expect(second.episodeKey, isNull);
    expect(second.metadataMatchStatus, MetadataMatchStatus.unmatched);
  });

  test('explicit numeric ID overrides a previously confirmed local match', () async {
    for (final id in ['1', '2']) {
      await db.saveMovieMetadata(Movie(tmdbId: id, title: id));
      await db.saveTVShowMetadata(TVShow(tmdbId: id, title: id));
    }
    final file = MediaFile(
      id: 0,
      path: '/example',
      fileName: 'example',
      parsedTitle: 'Example',
      explicitTmdbId: '2',
      movieTmdbId: '1',
      tvShowTmdbId: '1',
      addedAt: DateTime.utc(2026),
    );
    final resolver = MetadataMatcher(
      source: TmdbMetadataSource(api: TmdbApi()),
      repository: MetadataRepositoryImpl(database: db),
    );
    final candidate = ScrapeCandidateMapper.fromMediaFile(file);
    expect((await resolver.resolveMovie(candidate)).metadata!.tmdbId, '2');
    expect((await resolver.resolveTVShow(candidate)).metadata!.tmdbId, '2');
  });
}

class _EpisodeResolver extends MetadataMatcher {
  _EpisodeResolver(AppDatabase database)
    : super(
        source: TmdbMetadataSource(api: TmdbApi()),
        repository: MetadataRepositoryImpl(database: database),
      );
  @override
  bool get isConfigured => true;

  @override
  Future<MetadataMatch<TVShow>> resolveTVShow(ScrapeCandidate candidate) async => MetadataMatch.confirmed(
    const TVShow(tmdbId: '123', title: 'Show'),
    source: MetadataMatchSource.titleSearch,
  );

  @override
  Future<SeasonMetadata?> fetchSeason(String showId, int seasonNumber) async => const SeasonMetadata(
    season: Season(tvShowTmdbId: '123', seasonNumber: 1, title: 'Season'),
    episodes: [Episode(tvShowTmdbId: '123', seasonNumber: 1, episodeNumber: 1, title: 'One')],
  );
}
