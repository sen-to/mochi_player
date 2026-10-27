// 【旧库兼容测试】验证独立 DO 与 Mapper 可以原样打开既有第二版数据库。
// 基线由历史 schema 快照生成，检查物理结构、JSON、枚举及用户状态均保持。

import 'package:drift_dev/api/migrations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/data/database/app_database.dart';
import 'package:mochi_player/core/data/database/sqlite_setup.dart';
import 'package:mochi_player/core/domain/media/models.dart';

import '../../../generated/schema/schema.dart';

void main() {
  test('existing schema 2 opens without recreation and retains metadata and playback state', () async {
    final verifier = SchemaVerifier(GeneratedHelper(), setup: configureSqlite);
    final schema = await verifier.schemaAt(2);
    final raw = schema.rawDatabase;
    raw.execute('INSERT INTO storage_sources VALUES (?, ?, ?, ?, ?, ?, ?, ?)', [
      'nas',
      'NAS',
      'smb',
      'smb://server/share',
      '/',
      1,
      'viewer',
      'secret',
    ]);
    raw.execute('INSERT INTO movies (tmdb_id,title,rating,genres,cast) VALUES (?, ?, ?, ?, ?)', [
      '1',
      '旧电影',
      8.5,
      '["剧情"]',
      '[{"tmdbId":"7","name":"演员","character":"角色","profileUrl":null}]',
    ]);
    raw.execute(
      '''INSERT INTO media_files (source_id,path,file_name,parsed_title,media_type,
      metadata_match_status,size,is_hdr,duration,position,watch_status,is_favorite,added_at,movie_tmdb_id)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        'nas',
        '/movie.mkv',
        'movie.mkv',
        '旧电影',
        'movie',
        'confirmed',
        2048,
        0,
        100000,
        40000,
        'watching',
        1,
        '2026-10-01T00:00:00.000Z',
        '1',
      ],
    );
    final database = AppDatabase(schema.newConnection().executor);
    final service = database;
    addTearDown(service.close);
    await service.init();
    await verifier.migrateAndValidate(database, 2);
    await database.validateDatabaseSchema(setup: configureSqlite);
    final file = (await service.getMediaFile('nas', '/movie.mkv'))!;
    expect(file.position, 40000);
    expect(file.watchStatus, WatchStatus.watching);
    expect(file.metadataMatchStatus, MetadataMatchStatus.confirmed);
    expect(file.isFavorite, true);
    final movie = (await service.getMovieByTmdbId('1'))!;
    expect(movie.genres, ['剧情']);
    expect(movie.cast.single.character, '角色');
    expect((await service.getStorageSource('nas'))!.password, 'secret');
    await service.updateProgress(file, 60000);
    expect((await service.getMediaFile('nas', '/movie.mkv'))!.position, 60000);
    expect(raw.select('PRAGMA user_version').single['user_version'], 2);
  });
}
