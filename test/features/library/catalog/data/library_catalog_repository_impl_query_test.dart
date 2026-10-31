// 【行为测试】验证用 SQL 完成目录筛选、排序、分页及卡片元数据批量投影。
// 测试对象的职责边界：只返回有限展示结果和订阅，不处理弹窗或页面状态。

import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/data/database/app_database.dart';
import 'package:mochi_player/core/data/database/sqlite_setup.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/features/library/catalog/data/library_catalog_repository_impl.dart';

import '../../../../support/database_fixture.dart';

void main() {
  late AppDatabase database;
  late LibraryCatalogRepositoryImpl repository;
  late _SelectRecorder recorder;
  setUp(() async {
    recorder = _SelectRecorder();
    database = AppDatabase(NativeDatabase.memory(setup: configureSqlite).interceptWith(recorder));
    await database.init();
    repository = LibraryCatalogRepositoryImpl(database: database);
  });
  tearDown(() => database.close());

  for (final favorites in [true, false]) {
    test('100 mixed ${favorites ? 'favorite' : 'continue watching'} cards use three queries', () async {
      final files = [
        for (var i = 0; i < 60; i++) ...[
          _file('/movie/$i', movieId: '$i', order: i * 2),
          _file('/show/$i', showId: '$i', order: i * 2 + 1),
        ],
      ];
      await saveMediaFixture(database, files);
      for (var i = 0; i < 60; i++) {
        await database.saveMovieMetadata(
          Movie(
            tmdbId: '$i',
            title: 'Movie $i',
            releaseYear: 2020,
            posterUrl: 'movie-poster/$i',
            backdropUrl: 'movie-backdrop/$i',
            rating: 7,
          ),
        );
        await database.saveTVShowMetadata(
          TVShow(
            tmdbId: '$i',
            title: 'Show $i',
            releaseYear: 2021,
            posterUrl: 'show-poster/$i',
            backdropUrl: 'show-backdrop/$i',
            rating: 8,
          ),
        );
      }
      recorder.selects.clear();
      final cards = await (favorites ? repository.watchFavorites() : repository.watchContinueWatching()).first;
      expect(cards, hasLength(100));
      expect(recorder.selects, hasLength(3));
      final expected = favorites ? files.take(100) : files.reversed.take(100);
      expect(cards.map((card) => card.file.path), expected.map((file) => file.path));
      for (final card in cards) {
        final isShow = card.file.mediaType == MediaType.episode;
        final id = isShow ? card.file.tvShowTmdbId! : card.file.movieTmdbId!;
        expect(card.libraryItem, isShow ? isA<TVShow>() : isA<Movie>());
        expect(card.title, '${isShow ? 'Show' : 'Movie'} $id');
        expect(card.imageUrl, '${isShow ? 'show' : 'movie'}-${favorites ? 'poster' : 'backdrop'}/$id');
        expect(card.rating, isShow ? 8 : 7);
        expect(
          card.subtitle,
          !favorites && isShow
              ? 'S01E01'
              : isShow
              ? '2021'
              : '2020',
        );
      }
      // 元数据读取必须限制在当前页，不能加载整个媒体库。
      expect(recorder.selects.skip(1).fold<int>(0, (count, read) => count + read.arguments.length), 100);
    });

    test('unmatched ${favorites ? 'favorite' : 'continue watching'} cards need only the list query', () async {
      await saveMediaFixture(database, [_file('/unmatched')]);
      recorder.selects.clear();
      final cards = await (favorites ? repository.watchFavorites() : repository.watchContinueWatching()).first;
      expect(recorder.selects, hasLength(1));
      expect(cards.single.title, 'Parsed title');
      expect(cards.single.libraryItem, isNull);
      expect(cards.single.imageUrl, isNull);
      expect(cards.single.rating, 0);
    });

    test(
      'metadata updates refresh ${favorites ? 'favorite' : 'continue watching'} cards within three queries',
      () async {
        await saveMediaFixture(database, [_file('/movie', movieId: '1'), _file('/show', showId: '1')]);
        final updates = StreamIterator(favorites ? repository.watchFavorites() : repository.watchContinueWatching());
        try {
          expect(await updates.moveNext().timeout(const Duration(seconds: 2)), isTrue);
          recorder.selects.clear();
          await database.saveMovieMetadata(const Movie(tmdbId: '1', title: 'Updated', rating: 9));
          expect(await updates.moveNext().timeout(const Duration(seconds: 2)), isTrue);
          expect(updates.current.singleWhere((card) => card.file.mediaType == MediaType.movie).title, 'Updated');
          expect(recorder.selects, hasLength(3));
        } finally {
          await updates.cancel();
        }
      },
    );
  }

  test('a missing association does not resolve to a literal null metadata ID', () async {
    await saveMediaFixture(database, [_file('/unmatched'), _file('/matched', movieId: 'null')]);
    await database.saveMovieMetadata(const Movie(tmdbId: 'null', title: 'Matched movie'));
    final cards = await repository.watchFavorites().first;
    expect(cards.first.file.path, '/unmatched');
    expect(cards.first.libraryItem, isNull);
    expect(cards.first.title, 'Parsed title');
    expect(cards.last.title, 'Matched movie');
  });

  test('expanded pages split metadata IDs into bounded batches', () async {
    await saveMediaFixture(database, [for (var i = 0; i < 405; i++) _file('/$i', movieId: '$i')]);
    recorder.selects.clear();
    final cards = await repository.watchFavorites(limit: 405).first;
    expect(cards, hasLength(405));
    expect(recorder.selects, hasLength(3));
    expect(recorder.selects.skip(1).map((read) => read.arguments.length), [400, 5]);
  });
}

MediaFile _file(String path, {String? movieId, String? showId, int order = 0}) => MediaFile(
  id: 0,
  sourceId: 'nas',
  path: path,
  fileName: path,
  parsedTitle: 'Parsed title',
  mediaType: showId == null ? MediaType.movie : MediaType.episode,
  movieTmdbId: movieId,
  tvShowTmdbId: showId,
  parsedSeason: showId == null ? null : 1,
  parsedEpisode: showId == null ? null : 1,
  episodeKey: showId == null ? null : '${showId}_s1e1',
  isFavorite: true,
  watchStatus: WatchStatus.watching,
  position: 1000,
  duration: 10000,
  lastWatchedAt: DateTime.utc(2026).add(Duration(seconds: order)),
  addedAt: DateTime.utc(2026),
);

class _SelectRecorder extends QueryInterceptor {
  final selects = <({String statement, List<Object?> arguments})>[];

  @override
  Future<List<Map<String, Object?>>> runSelect(QueryExecutor executor, String statement, List<Object?> args) {
    selects.add((statement: statement, arguments: List.of(args)));
    return super.runSelect(executor, statement, args);
  }
}
