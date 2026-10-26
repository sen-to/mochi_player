import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/infrastructure/database/app_database.dart';
import 'package:mochi_player/core/infrastructure/database/database_service.dart';
import 'package:mochi_player/core/infrastructure/database/sqlite_setup.dart';
import 'package:mochi_player/core/domain/media/season_metadata.dart';
import 'package:mochi_player/features/library/infrastructure/database_metadata_repository.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

MediaFile file(String path, {String source = 'nas'}) => MediaFile(
  id: 0,
  sourceId: source,
  path: path,
  fileName: path,
  parsedTitle: 'Example',
  mediaType: MediaType.movie,
  addedAt: DateTime.utc(2026, 10, 11, 1, 2, 3, 4, 5),
);

StorageSourceRow source(String id) => StorageSourceRow(
  sourceId: id,
  name: id,
  type: 'local',
  endpoint: '/media',
  rootPath: '/',
  enabled: true,
  username: 'user',
  password: 'secret',
);

void main() {
  // Independent executors verify SQLite concurrency; production shares one connection.
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  tearDownAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = false);
  late DatabaseService service;
  setUp(() async {
    service = DatabaseService.withDatabase(AppDatabase(NativeDatabase.memory(setup: configureSqlite)));
    await service.init();
    await service.saveStorageSource(source('nas'));
    await service.saveStorageSource(source('other'));
  });
  tearDown(() => service.close());

  test('composite file identity does not collide on path separators', () async {
    await service.saveStorageSource(source('nas:/root'));
    await service.saveScannedFiles([file('/root:/same'), file('/same', source: 'nas:/root')]);
    expect(await service.database.select(service.database.mediaFiles).get(), hasLength(2));
    expect((await service.getMediaFile('nas', '/root:/same'))!.sourceId, 'nas');
    expect((await service.getMediaFile('nas:/root', '/same'))!.sourceId, 'nas:/root');
  });

  test('foreign keys reject orphan sources and metadata', () async {
    await expectLater(
      service.saveScannedFiles([file('/orphan', source: 'missing')]),
      throwsA(isA<sqlite.SqliteException>()),
    );
    final entry = file('/a');
    await service.saveScannedFiles([entry]);
    await expectLater(
      service.updateMediaMatches([entry.copyWith(movieTmdbId: 'missing')]),
      throwsA(isA<sqlite.SqliteException>()),
    );
    await expectLater(
      service.saveSeasonEpisodes(const Season(tvShowTmdbId: 'missing', seasonNumber: 1, title: 'Season'), const []),
      throwsA(isA<sqlite.SqliteException>()),
    );
    expect((await service.getMediaFile('nas', '/a'))!.movieTmdbId, isNull);
  });

  test('episode association cannot refer to another show and import rolls back', () async {
    for (final id in ['1', '2']) {
      await service.saveTVShowMetadata(TVShow(tmdbId: id, title: 'Show'));
    }
    await service.saveSeasonEpisodes(const Season(tvShowTmdbId: '1', seasonNumber: 0, title: 'Specials'), const [
      Episode(tvShowTmdbId: '1', seasonNumber: 0, episodeNumber: 1, tmdbId: '77', title: 'Special'),
    ]);
    final entry = file('/special').copyWith(mediaType: MediaType.episode, parsedSeason: 0, parsedEpisode: 1);
    await service.saveScannedFiles([entry]);
    await expectLater(
      service.updateMediaMatches([entry.copyWith(tvShowTmdbId: '2', episodeKey: '1_s0e1')]),
      throwsA(isA<sqlite.SqliteException>()),
    );
    await expectLater(
      service.saveSeasonEpisodes(const Season(tvShowTmdbId: '2', seasonNumber: 1, title: 'Season'), const [
        Episode(tvShowTmdbId: '2', seasonNumber: 99, episodeNumber: 1, title: 'Wrong season'),
      ]),
      throwsA(isA<sqlite.SqliteException>()),
    );
    final seasons = await service.database.select(service.database.seasons).get();
    expect(seasons.map((s) => s.tvShowTmdbId), ['1']);
    expect((await service.getMediaFile('nas', '/special'))!.episodeKey, isNull);
  });

  test('invalid attributes and mixed metadata types are rejected', () async {
    await expectLater(
      service.saveScannedFiles([file('/bad').copyWith(size: -1)]),
      throwsA(isA<sqlite.SqliteException>()),
    );
    await service.saveTVShowMetadata(const TVShow(tmdbId: '1', title: 'Show'));
    await expectLater(
      service.saveScannedFiles([file('/movie').copyWith(tvShowTmdbId: '1')]),
      throwsA(isA<sqlite.SqliteException>()),
    );
  });

  test('source deletion cascades while referenced metadata is protected', () async {
    final entry = file('/a');
    await service.saveScannedFiles([entry]);
    await DatabaseMetadataRepository(database: service).importMovie(const Movie(tmdbId: '1', title: 'Movie'), entry);
    await expectLater(service.database.delete(service.database.movies).go(), throwsA(isA<sqlite.SqliteException>()));
    expect(await service.deleteStorageSource('nas'), isTrue);
    expect(await service.getMediaFile('nas', '/a'), isNull);
    expect(await service.getMovieByTmdbId('1'), isNotNull);
    expect((await service.database.customSelect('PRAGMA foreign_key_check').get()), isEmpty);
  });

  test('SQL composite cascade refreshes drift episode subscriptions', () async {
    await service.saveTVShowMetadata(const TVShow(tmdbId: '1', title: 'Show'));
    await service.saveSeasonEpisodes(const Season(tvShowTmdbId: '1', seasonNumber: 1, title: 'Season'), const [
      Episode(tvShowTmdbId: '1', seasonNumber: 1, episodeNumber: 1, title: 'Episode'),
    ]);
    final stream = StreamIterator(service.database.select(service.database.episodes).watch());
    try {
      expect(await stream.moveNext().timeout(const Duration(seconds: 2)), isTrue);
      expect(stream.current, hasLength(1));
      await service.database.delete(service.database.tVShows).go();
      expect(await stream.moveNext().timeout(const Duration(seconds: 2)), isTrue);
      expect(stream.current, isEmpty);
      expect(await service.database.select(service.database.seasons).get(), isEmpty);
    } finally {
      await stream.cancel();
    }
  });

  test('v1 development reset is atomic and safe for concurrent openers', () async {
    final dir = await Directory.systemTemp.createTemp('mochi-schema-reset-');
    final path = File('${dir.path}/library.sqlite');
    final legacy = sqlite.sqlite3.open(path.path);
    for (final name in ['media_files', 'movies', 't_v_shows', 'seasons', 'episodes', 'storage_sources']) {
      legacy.execute('CREATE TABLE $name (legacy_value TEXT)');
      legacy.execute("INSERT INTO $name VALUES ('old development data')");
    }
    legacy.execute('PRAGMA user_version = 1');
    legacy.dispose();
    DatabaseService open() =>
        DatabaseService.withDatabase(AppDatabase(NativeDatabase.createInBackground(path, setup: configureSqlite)));
    final first = open();
    final second = open();
    try {
      await Future.wait([first.init(), second.init()]);
      expect(await first.getStorageSources(), isEmpty);
      expect((await first.database.customSelect('PRAGMA user_version').getSingle()).read<int>('user_version'), 2);
      await first.saveStorageSource(source('nas'));
      await first.saveScannedFiles([file('/new')]);
      expect(await second.getMediaFile('nas', '/new'), isNotNull);
      expect(await second.database.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
    } finally {
      await first.close();
      await second.close();
      await dir.delete(recursive: true);
    }
  });

  test('upsert keeps identity and separates same path across sources', () async {
    final original = file('/a');
    await service.saveScannedFiles([original]);
    final before = (await service.getMediaFile('nas', '/a'))!;
    await service.saveScannedFiles([original.copyWith(size: 99), file('/a', source: 'other')]);
    final after = (await service.getMediaFile('nas', '/a'))!;
    expect(after.id, before.id);
    expect(after.size, 99);
    expect(await service.database.select(service.database.mediaFiles).get(), hasLength(2));
    expect(after.addedAt, original.addedAt);
  });

  test('repeated stale scans cannot reset progress, favorite or metadata', () async {
    final stale = file('/a');
    await service.saveScannedFiles([stale]);
    await DatabaseMetadataRepository(
      database: service,
    ).importMovie(const Movie(tmdbId: '123', title: 'Example'), stale);
    await service.updateProgress(stale, 42000, duration: 100000);
    await service.setTitleFavorite(const Movie(tmdbId: '123', title: 'Movie'), true);
    await service.saveScannedFiles([stale.copyWith(size: 999, parsedTitle: 'Updated')]);
    await service.saveScannedFiles([stale.copyWith(parsedTitle: 'Reparsed', size: 999)]);
    final current = (await service.getMediaFile('nas', '/a'))!;
    expect(current.position, 42000);
    expect(current.duration, 100000);
    expect(current.watchStatus, WatchStatus.watching);
    expect(current.lastWatchedAt, isNotNull);
    expect(current.isFavorite, isTrue);
    expect(current.movieTmdbId, '123');
    expect(current.metadataMatchStatus, MetadataMatchStatus.confirmed);
    expect(current.size, 999);
    expect(current.parsedTitle, 'Reparsed');
  });

  test('stale matched and unmatched imports preserve playback state', () async {
    final stale = file('/a');
    await service.saveScannedFiles([stale]);
    await service.updateProgress(stale, 99000, duration: 100000);
    final importer = DatabaseMetadataRepository(database: service);
    await importer.importMovie(const Movie(tmdbId: '123', title: 'Example'), stale);
    await service.setTitleFavorite(const Movie(tmdbId: '123', title: 'Movie'), true);
    await importer.markUnmatched([stale]);
    final current = (await service.getMediaFile('nas', '/a'))!;
    expect(current.watchStatus, WatchStatus.completed);
    expect(current.position, 99000);
    expect(current.isFavorite, isTrue);
    expect(current.movieTmdbId, isNull);
    expect(current.metadataMatchStatus, MetadataMatchStatus.unmatched);
  });

  test('type changes reset stored associations, but preserve user state', () async {
    final stale = file('/a');
    await service.saveScannedFiles([stale]);
    await service.saveMovieMetadata(const Movie(tmdbId: '123', title: 'Movie'));
    await service.updateMediaMatches([
      stale.copyWith(movieTmdbId: '123', metadataMatchStatus: MetadataMatchStatus.confirmed),
    ]);
    await service.updateProgress(stale, 30, duration: 100);
    await service.saveScannedFiles([stale.copyWith(mediaType: MediaType.episode, parsedSeason: 1, parsedEpisode: 1)]);
    var current = (await service.getMediaFile('nas', '/a'))!;
    expect(current.movieTmdbId, isNull);
    expect(current.position, 30);
    expect(current.metadataMatchStatus, MetadataMatchStatus.pending);
    await service.saveTVShowMetadata(const TVShow(tmdbId: '456', title: 'Show'));
    await service.saveSeasonEpisodes(const Season(tvShowTmdbId: '456', seasonNumber: 1, title: 'Season'), const [
      Episode(tvShowTmdbId: '456', seasonNumber: 1, episodeNumber: 1, title: 'Episode'),
    ]);
    await service.updateMediaMatches([current.copyWith(tvShowTmdbId: '456', episodeKey: '456_s1e1')]);
    await service.saveScannedFiles([stale]);
    current = (await service.getMediaFile('nas', '/a'))!;
    expect(current.tvShowTmdbId, isNull);
    expect(current.episodeKey, isNull);
    expect(current.mediaType, MediaType.movie);
    expect(current.position, 30);
  });

  test('progress boundaries and title favorite apply to all physical versions', () async {
    await service.saveMovieMetadata(const Movie(tmdbId: '123', title: 'Movie'));
    final a = file('/a').copyWith(movieTmdbId: '123');
    final b = file('/b').copyWith(movieTmdbId: '123');
    await service.saveScannedFiles([a, b]);
    expect(await service.setTitleFavorite(const Movie(tmdbId: '123', title: 'Movie'), true), isTrue);
    expect(await service.setTitleFavorite(const Movie(tmdbId: 'missing', title: 'Movie'), true), isFalse);
    expect((await service.getMediaFile('nas', '/b'))!.isFavorite, isTrue);
    await service.updateProgress(a, -1, duration: 100);
    expect((await service.getMediaFile('nas', '/a'))!.watchStatus, WatchStatus.notStarted);
    await service.updateProgress(a, 950, duration: 1000);
    expect((await service.getMediaFile('nas', '/a'))!.watchStatus, WatchStatus.completed);
    await service.updateProgress(a, 2000, duration: 1000);
    expect((await service.getMediaFile('nas', '/a'))!.position, 1000);
  });

  test('domain metadata roundtrips nullable values, cast, genres and certification', () async {
    final movie = Movie(
      tmdbId: '123',
      title: '电影',
      originalTitle: 'Original',
      certification: 'PG-13',
      rating: 8.2,
      releaseDate: DateTime.utc(2026, 1, 2, 3, 4, 5, 6, 7),
      genres: const ['剧情'],
      cast: const [Artist(tmdbId: '7', name: '演员', character: '主角')],
    );
    await service.saveMovieMetadata(movie);
    final stored = (await service.getMovieByTmdbId('123'))!;
    expect(stored.certification, 'PG-13');
    expect(stored.releaseDate, movie.releaseDate);
    expect(stored.cast.single.name, '演员');
    expect(stored.cast.single.character, '主角');
    expect(stored.genres, ['剧情']);
    await service.saveMovieMetadata(const Movie(tmdbId: '123', title: 'Updated'));
    expect((await service.getMovieByTmdbId('123'))!.certification, isNull);
    expect(await service.database.select(service.database.movies).get(), hasLength(1));
  });

  test('season import returns explicit matched keys without mutating snapshots', () async {
    final files = [
      file('/1').copyWith(mediaType: MediaType.episode, parsedSeason: 1, parsedEpisode: 1),
      file('/2').copyWith(mediaType: MediaType.episode, parsedSeason: 1, parsedEpisode: 2),
    ];
    await service.saveScannedFiles(files);
    await service.updateProgress(files.first, 30, duration: 100);
    await service.saveTVShowMetadata(const TVShow(tmdbId: '123', title: 'Show'));
    final keys = await DatabaseMetadataRepository(database: service).importSeasonEpisodes(
      const SeasonMetadata(
        season: Season(tvShowTmdbId: '123', seasonNumber: 1, title: 'Season'),
        episodes: [Episode(tvShowTmdbId: '123', seasonNumber: 1, episodeNumber: 1, title: 'One')],
      ),
      '123',
      files,
    );
    expect(keys, {'nas:/1'});
    expect(files.first.episodeKey, isNull);
    final matched = (await service.getMediaFile('nas', '/1'))!;
    expect(matched.episodeKey, '123_s1e1');
    expect(matched.position, 30);
    expect((await service.getMediaFile('nas', '/2'))!.episodeKey, isNull);
  });

  test('clear library keeps configured sources; source deletion removes owned files', () async {
    await service.saveStorageSource(source('nas'));
    await service.saveStorageSource(source('other'));
    await service.saveScannedFiles([file('/a'), file('/a', source: 'other')]);
    expect(await service.deleteStorageSourceAndMediaFiles('nas'), 1);
    expect(await service.getMediaFile('other', '/a'), isNotNull);
    expect(await service.deleteStorageSourceAndMediaFiles('missing'), isNull);
    await service.clearLibrary();
    expect(await service.getStorageSources(), hasLength(1));
    expect(await service.database.select(service.database.mediaFiles).get(), isEmpty);
  });

  test('a failed bulk discovery rolls back the complete batch', () async {
    await service.database.customStatement('''CREATE TRIGGER reject_bad BEFORE INSERT ON media_files
      WHEN NEW.path='/bad' BEGIN SELECT RAISE(ABORT,'bad file'); END''');
    await expectLater(service.saveScannedFiles([file('/good'), file('/bad')]), throwsA(isA<Exception>()));
    expect(await service.database.select(service.database.mediaFiles).get(), isEmpty);
  });

  test('bulk discovery uses a batched request without per-row SELECT or RETURNING', () async {
    final recorder = _BatchRecorder();
    final db = DatabaseService.withDatabase(
      AppDatabase(NativeDatabase.memory(setup: configureSqlite).interceptWith(recorder)),
    );
    try {
      await db.init();
      await db.saveStorageSource(source('nas'));
      recorder.batches.clear();
      recorder.selects.clear();
      await db.saveScannedFiles(List.generate(300, (i) => file('/$i')));
      expect(recorder.batches, hasLength(1));
      expect(recorder.batches.single.arguments, hasLength(600));
      expect(recorder.batches.single.statements.every((s) => !s.contains('RETURNING')), isTrue);
      expect(recorder.selects, isEmpty);
    } finally {
      await db.close();
    }
  });

  test('independent WAL connections write concurrently and survive reopening', () async {
    final dir = await Directory.systemTemp.createTemp('mochi-sqlite-test-');
    final path = File('${dir.path}/library.sqlite');
    DatabaseService open() =>
        DatabaseService.withDatabase(AppDatabase(NativeDatabase.createInBackground(path, setup: configureSqlite)));
    final first = open();
    final second = open();
    try {
      await Future.wait([first.init(), second.init()]);
      await first.saveStorageSource(source('nas'));
      await first.saveStorageSource(source('other'));
      await Future.wait([
        first.saveScannedFiles(List.generate(40, (i) => file('/$i'))),
        second.saveScannedFiles(List.generate(40, (i) => file('/$i', source: 'other'))),
      ]);
      await first.close();
      await second.close();
      final reopened = open();
      try {
        await reopened.init();
        expect(await reopened.database.select(reopened.database.mediaFiles).get(), hasLength(80));
      } finally {
        await reopened.close();
      }
    } finally {
      await first.close();
      await second.close();
      await dir.delete(recursive: true);
    }
  });
}

class _BatchRecorder extends QueryInterceptor {
  final List<BatchedStatements> batches = [];
  final List<String> selects = [];

  @override
  Future<void> runBatched(QueryExecutor executor, BatchedStatements statements) {
    batches.add(statements);
    return super.runBatched(executor, statements);
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(QueryExecutor executor, String statement, List<Object?> args) {
    selects.add(statement);
    return super.runSelect(executor, statement, args);
  }
}
