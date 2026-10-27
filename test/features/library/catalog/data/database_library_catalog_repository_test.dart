// 【行为测试】验证用 SQL 完成目录筛选、排序、分页及卡片元数据批量投影。
// 测试对象的职责边界：只返回有限展示结果和订阅，不处理弹窗或页面状态。

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/data/database/app_database.dart';
import 'package:mochi_player/core/data/database/mappers/media_file_mapper.dart';
import 'package:mochi_player/core/data/database/sqlite_setup.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/features/library/catalog/data/database_library_catalog_repository.dart';
import 'package:mochi_player/features/library/sync/data/database_library_sync_repository.dart';
import 'package:mochi_player/features/playback/data/database_playback_media_repository.dart';

import '../../../../support/database_fixture.dart';
import '../../../../support/library_continue_watching_reference.dart';
import '../../../../support/library_search_reference.dart';

MediaFile file(
  String path, {
  String? movieId,
  String? showId,
  int? season,
  int? episode,
  WatchStatus status = WatchStatus.notStarted,
  DateTime? watched,
  bool favorite = false,
  DateTime? added,
}) => MediaFile(
  id: 0,
  sourceId: 'nas',
  path: path,
  fileName: path,
  parsedTitle: 'Example Show',
  mediaType: showId != null || episode != null ? MediaType.episode : MediaType.movie,
  movieTmdbId: movieId,
  tvShowTmdbId: showId,
  episodeKey: showId == null ? null : '${showId}_s${season}e$episode',
  parsedSeason: season,
  parsedEpisode: episode,
  watchStatus: status,
  lastWatchedAt: watched,
  isFavorite: favorite,
  addedAt: added ?? DateTime.utc(2026),
);

void main() {
  late AppDatabase db;
  late DatabaseLibraryCatalogRepository repository;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory(setup: configureSqlite));
    await db.init();
    repository = DatabaseLibraryCatalogRepository(db);
  });
  tearDown(() => db.close());

  test('identical movie and show provider IDs stay separate in versions and favorites', () async {
    const movie = Movie(tmdbId: '123', title: 'Movie');
    const show = TVShow(tmdbId: '123', title: 'Show');
    await saveMediaFixture(db, [
      file('/movie', movieId: '123'),
      file('/episode', showId: '123', season: 1, episode: 1),
    ]);
    expect((await repository.getVersions(movie)).map((f) => f.path), ['/movie']);
    expect((await repository.getVersions(show)).map((f) => f.path), ['/episode']);
    await db.setTitleFavorite(movie, true);
    expect((await repository.watchVersions(movie).first).single.isFavorite, isTrue);
    expect((await repository.watchVersions(show).first).single.isFavorite, isFalse);
    await db.setTitleFavorite(show, true);
    await db.setTitleFavorite(movie, false);
    expect((await repository.watchVersions(show).first).single.isFavorite, isTrue);
  });

  test('show and season queries use composite indexes without a sort buffer', () async {
    for (final sql in [
      "SELECT * FROM seasons WHERE tv_show_tmdb_id='123' ORDER BY season_number",
      "SELECT * FROM episodes WHERE tv_show_tmdb_id='123' ORDER BY season_number, episode_number",
      "SELECT * FROM media_files WHERE tv_show_tmdb_id='123' ORDER BY parsed_season, parsed_episode, path",
    ]) {
      final plan = (await db.customSelect('EXPLAIN QUERY PLAN $sql').get())
          .map((r) => r.read<String>('detail'))
          .join('\n');
      expect(plan, contains('USING INDEX'));
      expect(plan, isNot(contains('USE TEMP B-TREE')));
    }
  });

  test('titles use physical availability, filtering and paging in SQL', () async {
    expect(await repository.watchHero().first, isNull);
    for (var i = 0; i < 125; i++) {
      await db.saveMovieMetadata(Movie(tmdbId: '$i', title: 'Movie $i'));
    }
    await saveMediaFixture(db, [for (var i = 0; i < 124; i++) file('/$i', movieId: '$i')]);
    expect(await repository.watchTitles(kind: 'movie', limit: 100).first, hasLength(100));
    expect(await repository.watchTitles(kind: 'movie', limit: 200).first, hasLength(124));
    expect((await repository.watchTitles(query: 'Movie 123').first).single.tmdbId, '123');
    expect(await repository.watchTitles(query: 'Movie 124').first, isEmpty);
    await DatabaseLibrarySyncRepository(database: db).removeMissingFiles('nas', {'/123'});
    expect((await repository.watchTitles().first).single.tmdbId, '123');
    expect((await repository.watchHero().first)!.tmdbId, '123');
  });

  test('Unicode and punctuation search ranks display and original titles like the matcher', () async {
    const movies = [
      Movie(tmdbId: '1', title: 'Ａ 电影', originalTitle: 'Dune Part Two'),
      Movie(tmdbId: '2', title: 'Dune: Part Two Special'),
      Movie(tmdbId: '3', title: 'Dune.Part-Two'),
    ];
    for (final movie in movies) {
      await db.saveMovieMetadata(movie);
    }
    await saveMediaFixture(db, [for (final movie in movies) file('/${movie.tmdbId}', movieId: movie.tmdbId)]);
    for (final query in ['dune part two', '电影', 'DUNE:PART-TWO', '%', '" OR 1=1']) {
      final actual = await repository.watchTitles(query: query).first;
      expect(actual.map((m) => m.tmdbId), LibrarySearchReference.libraryItems(movies, query).map((m) => m.tmdbId));
    }
  });

  test('recently added uses earliest physical version date per title', () async {
    await db.saveMovieMetadata(const Movie(tmdbId: '1', title: 'One'));
    await db.saveMovieMetadata(const Movie(tmdbId: '2', title: 'Two'));
    await saveMediaFixture(db, [
      file('/1a', movieId: '1', added: DateTime.utc(2020)),
      file('/1b', movieId: '1', added: DateTime.utc(2026)),
      file('/2', movieId: '2', added: DateTime.utc(2023)),
    ]);
    expect((await repository.watchTitles(recent: true).first).map((m) => m.tmdbId), ['2', '1']);
  });

  test('detail reads only its own seasons and episodes and preserves certification', () async {
    const show = TVShow(tmdbId: '123', title: 'Example', certification: 'TV-14');
    await db.saveTVShowMetadata(show);
    await db.saveSeasonEpisodes(const Season(tvShowTmdbId: '123', seasonNumber: 1, title: 'Season'), const [
      Episode(tvShowTmdbId: '123', seasonNumber: 1, episodeNumber: 2, title: 'Two'),
      Episode(tvShowTmdbId: '123', seasonNumber: 1, episodeNumber: 1, title: 'One'),
    ]);
    await db.saveTVShowMetadata(const TVShow(tmdbId: '1234', title: 'Other'));
    await db.saveSeasonEpisodes(const Season(tvShowTmdbId: '1234', seasonNumber: 1, title: 'Other'), const [
      Episode(tvShowTmdbId: '1234', seasonNumber: 1, episodeNumber: 1, title: 'Other'),
    ]);
    final item = await repository.watchDetail(show).first as TVShow;
    expect(item.certification, 'TV-14');
    expect(item.seasons, hasLength(1));
    expect(item.seasons.single.episodes.map((e) => e.episodeNumber), [1, 2]);
  });

  test('playback queue scopes one show and orders seasons and episodes', () async {
    final current = file('/s1e2', showId: '123', season: 1, episode: 2);
    await saveMediaFixture(db, [
      current,
      file('/s2e1', showId: '123', season: 2, episode: 1),
      file('/s1e1', showId: '123', season: 1, episode: 1),
      file('/other', showId: '456', season: 1, episode: 1),
    ]);
    expect((await repository.getPlaybackQueue(current)).map((f) => f.path), ['/s1e1', '/s1e2', '/s2e1']);
    expect((await repository.getEpisodeFile('123_s1e2'))!.path, '/s1e2');
  });

  test('favorites deduplicate versions and retain unmatched file fallback', () async {
    await db.saveTVShowMetadata(const TVShow(tmdbId: '123', title: 'Show'));
    await saveMediaFixture(db, [
      file('/1', showId: '123', season: 1, episode: 1, favorite: true),
      file('/2', showId: '123', season: 1, episode: 2, favorite: true),
      file('/loose', favorite: true),
    ]);
    final cards = await repository.watchFavorites().first;
    expect(cards, hasLength(2));
    expect(cards.first.libraryItem!.title, 'Show');
    expect((await repository.watchFavorites(query: 'Show').first), hasLength(2));
  });

  test('continue watching advances to next episode and excludes completed titles before LIMIT', () async {
    await saveMediaFixture(db, [
      file(
        '/end',
        showId: '1',
        season: 1,
        episode: 1,
        status: WatchStatus.completed,
        watched: DateTime.utc(2026, 10, 3),
      ),
      file(
        '/done',
        showId: '2',
        season: 1,
        episode: 1,
        status: WatchStatus.completed,
        watched: DateTime.utc(2026, 10, 2),
      ),
      file('/next', showId: '2', season: 1, episode: 2),
      file('/movie', movieId: '3', status: WatchStatus.watching, watched: DateTime.utc(2026, 10, 1)),
    ]);
    final cards = await repository.watchContinueWatching(limit: 1).first;
    expect(cards.single.file.path, '/next');
    final all = await db.select(db.mediaFiles).get();
    expect(
      (await repository.watchContinueWatching(limit: 100).first).map((c) => c.file.path),
      LibraryContinueWatchingReference.resolve(all.map(MediaFileMapper.toDomain)).map((c) => c.file.path),
    );
  });

  test('continue watching matches domain policy with versions, missing IDs and crossed seasons', () async {
    final entries = <MediaFile>[];
    for (var i = 0; i < 30; i++) {
      for (var e = 1; e <= 5; e++) {
        entries.add(
          file(
            '/$i/$e',
            showId: '${100 + i}',
            season: e < 4 ? 1 : 2,
            episode: e < 4 ? e : e - 3,
            status: e == 1
                ? WatchStatus.completed
                : e == 2 && i.isEven
                ? WatchStatus.watching
                : WatchStatus.notStarted,
            watched: e <= 2 ? DateTime.utc(2026, 10, 1, e) : null,
          ),
        );
      }
      entries.add(file('/$i/1-alt', showId: '${100 + i}', season: 1, episode: 1));
    }
    entries.add(file('/unmatched1', season: 1, episode: 1, status: WatchStatus.completed, watched: DateTime.utc(2026)));
    entries.add(file('/unmatched2', season: 1, episode: 2));
    await saveMediaFixture(db, entries);
    final all = await db.select(db.mediaFiles).get();
    final expected = LibraryContinueWatchingReference.resolve(
      all.map(MediaFileMapper.toDomain),
    ).map((t) => t.file.path).toSet();
    final actual = (await repository.watchContinueWatching(limit: 100).first).map((c) => c.file.path).toSet();
    expect(actual, expected);
  });

  test('shared library subscriptions receive playback-store progress without window notifications', () async {
    final entry = file('/movie', movieId: '1');
    await saveMediaFixture(db, [entry]);
    final stream = StreamIterator(repository.watchVersions(const Movie(tmdbId: '1', title: 'Movie')));
    try {
      expect(await stream.moveNext().timeout(const Duration(seconds: 2)), isTrue);
      expect(stream.current.single.isFavorite, isFalse);
      await db.setTitleFavorite(const Movie(tmdbId: '1', title: 'Movie'), true);
      expect(await stream.moveNext().timeout(const Duration(seconds: 2)), isTrue);
      expect(stream.current.single.isFavorite, isTrue);
      await DatabasePlaybackMediaRepository(database: db).updateProgress(entry, 42000, duration: 100000);
      expect(await stream.moveNext().timeout(const Duration(seconds: 2)), isTrue);
      expect(stream.current.single.position, 42000);
      expect(stream.current.single.duration, 100000);
      expect(stream.current.single.isFavorite, isTrue);
    } finally {
      await stream.cancel();
    }
  });

  test('scrape candidates exclude persisted matches and handle explicit numeric overrides', () async {
    await db.saveMovieMetadata(const Movie(tmdbId: '1', title: 'Movie'));
    await saveMediaFixture(db, [
      file('/confirmed', movieId: '1'),
      file('/missing'),
      file('/override', movieId: '1').copyWith(explicitTmdbId: '3'),
      file('/nonnumeric', movieId: '1').copyWith(explicitTmdbId: '1_s1e1'),
    ]);
    expect((await DatabaseLibrarySyncRepository(database: db).scrapeCandidates()).map((f) => f.path), [
      '/missing',
      '/override',
    ]);
  });
}
