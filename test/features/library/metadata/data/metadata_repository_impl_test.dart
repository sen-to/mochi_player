// 【行为测试】验证将元数据读取与原子关联导入适配到共享数据库。
// 测试对象的职责边界：导入不覆盖用户收藏或观看进度，不负责网络匹配。

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/data/database/app_database.dart';
import 'package:mochi_player/core/data/database/sqlite_setup.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/domain/media/season_metadata.dart';
import 'package:mochi_player/features/library/metadata/data/metadata_repository_impl.dart';

import '../../../../support/database_fixture.dart';
import '../../../../support/library_sync_fakes.dart';

void main() {
  late AppDatabase database;
  late MetadataRepositoryImpl repository;
  setUp(() async {
    database = AppDatabase(NativeDatabase.memory(setup: configureSqlite));
    await database.init();
    repository = MetadataRepositoryImpl(database: database);
  });
  tearDown(() => database.close());

  test('concurrent imports count a newly discovered show once', () async {
    const show = TVShow(tmdbId: '2', title: 'Show');
    final imported = await Future.wait([repository.importTVShow(show), repository.importTVShow(show)]);
    expect(imported.where((isNew) => isNew), hasLength(1));
    expect((await repository.findTVShow('2'))!.title, 'Show');
  });

  test('failed association update rolls back movie metadata in the same transaction', () async {
    final file = libraryFile('/movie');
    await saveMediaFixture(database, [file]);
    await database.customStatement('''CREATE TRIGGER reject_match BEFORE UPDATE OF movie_tmdb_id
      ON media_files BEGIN SELECT RAISE(ABORT, 'match rejected'); END''');
    await expectLater(repository.importMovie(const Movie(tmdbId: '2', title: 'Movie'), file), throwsException);
    expect(await repository.findMovie('2'), isNull);
    expect((await database.getMediaFile('local', '/movie'))!.movieTmdbId, isNull);
  });

  test('failed association update rolls back the whole season import', () async {
    final file = libraryFile('/episode', season: 1, episode: 1);
    await saveMediaFixture(database, [file]);
    await repository.importTVShow(const TVShow(tmdbId: '2', title: 'Show'));
    await database.customStatement('''CREATE TRIGGER reject_match BEFORE UPDATE OF episode_key
      ON media_files BEGIN SELECT RAISE(ABORT, 'match rejected'); END''');
    await expectLater(
      repository.importSeasonEpisodes(
        const SeasonMetadata(
          season: Season(tvShowTmdbId: '2', seasonNumber: 1, title: 'Season'),
          episodes: [Episode(tvShowTmdbId: '2', seasonNumber: 1, episodeNumber: 1, title: 'Episode')],
        ),
        '2',
        [file],
      ),
      throwsException,
    );
    expect(await database.select(database.seasons).get(), isEmpty);
    expect(await database.select(database.episodes).get(), isEmpty);
    expect((await database.getMediaFile('local', '/episode'))!.episodeKey, isNull);
  });
}
