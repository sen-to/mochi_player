import 'package:mochi_player/core/infrastructure/tmdb/tmdb_service.dart';
import 'package:mochi_player/features/library/infrastructure/metadata_importer.dart';
import '../../../support/database_fixture.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/infrastructure/database/app_database.dart';
import 'package:mochi_player/core/infrastructure/database/database_service.dart';
import 'package:mochi_player/core/infrastructure/database/sqlite_setup.dart';
import 'package:mochi_player/core/infrastructure/tmdb/tmdb_season_result.dart';
import 'package:mochi_player/features/library/application/scrape_candidate.dart';
import 'package:mochi_player/features/library/infrastructure/metadata_match_resolver.dart';
import 'package:mochi_player/features/library/infrastructure/metadata_scraper.dart';

void main() {
  late DatabaseService db;
  setUp(() async {
    db = DatabaseService.withDatabase(AppDatabase(NativeDatabase.memory(setup: configureSqlite)));
    await db.init();
  });
  tearDown(() => db.close());

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
      importer: MetadataImporter(database: db),
      matchResolver: _EpisodeResolver(db),
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
    final resolver = MetadataMatchResolver(tmdb: TmdbService(), database: db);
    final candidate = ScrapeCandidate.fromMediaFile(file);
    expect((await resolver.resolveMovie(candidate)).metadata!.tmdbId, '2');
    expect((await resolver.resolveTVShow(candidate)).metadata!.tmdbId, '2');
  });
}

class _EpisodeResolver extends MetadataMatchResolver {
  _EpisodeResolver(DatabaseService database) : super(tmdb: TmdbService(), database: database);
  @override
  bool get isConfigured => true;

  @override
  Future<MetadataMatch<TVShow>> resolveTVShow(ScrapeCandidate candidate) async => MetadataMatch.confirmed(
    const TVShow(tmdbId: '123', title: 'Show'),
    source: MetadataMatchSource.titleSearch,
  );

  @override
  Future<TmdbSeasonResult?> fetchSeason(int tvId, int seasonNumber, {required String showTmdbId}) async =>
      const TmdbSeasonResult(
        season: Season(tvShowTmdbId: '123', seasonNumber: 1, title: 'Season'),
        episodes: [Episode(tvShowTmdbId: '123', seasonNumber: 1, episodeNumber: 1, title: 'One')],
      );
}
