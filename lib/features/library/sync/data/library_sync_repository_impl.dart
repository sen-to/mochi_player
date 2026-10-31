// 【数据访问】将扫描持久化契约适配到共享数据库。
// 负责扫描路径、分批写入与失效清理，不编排扫描顺序。

import 'package:drift/drift.dart';
import 'package:mochi_player/core/data/database/app_database.dart';
import 'package:mochi_player/core/data/database/mappers/media_file_mapper.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/features/library/sync/application/library_sync_repository.dart';

class LibrarySyncRepositoryImpl implements LibrarySyncRepository {
  LibrarySyncRepositoryImpl({required AppDatabase database}) : _database = database;

  final AppDatabase _database;

  @override
  Future<void> saveScannedFiles(List<MediaFile> files) => _database.saveScannedFiles(files);

  @override
  Future<Set<String>> sourcePaths(String sourceId) async {
    final query = _database.selectOnly(_database.mediaFiles)
      ..addColumns([_database.mediaFiles.path])
      ..where(_database.mediaFiles.sourceId.equals(sourceId));
    return (await query.get()).map((row) => row.read(_database.mediaFiles.path)!).toSet();
  }

  @override
  Future<int> removeMissingFiles(String sourceId, Set<String> seen) async {
    final missing = (await sourcePaths(sourceId)).difference(seen).toList();
    var deleted = 0;
    await _database.transaction(() async {
      for (var i = 0; i < missing.length; i += 400) {
        deleted += await (_database.delete(
          _database.mediaFiles,
        )..where((t) => t.sourceId.equals(sourceId) & t.path.isIn(missing.skip(i).take(400)))).go();
      }
    });
    return deleted;
  }

  @override
  Future<List<MediaFile>> scrapeCandidates() async {
    final sql = '''SELECT * FROM media_files f WHERE
      (media_type='movie' AND (NOT EXISTS(SELECT 1 FROM movies m WHERE m.tmdb_id=f.movie_tmdb_id)
        OR (explicit_tmdb_id<>'' AND explicit_tmdb_id NOT GLOB '*[^0-9]*' AND explicit_tmdb_id<>COALESCE(movie_tmdb_id,''))))
      OR (media_type='episode' AND (NOT EXISTS(SELECT 1 FROM episodes e WHERE e.episode_key=f.episode_key)
        OR (explicit_tmdb_id<>'' AND explicit_tmdb_id NOT GLOB '*[^0-9]*' AND explicit_tmdb_id<>COALESCE(tv_show_tmdb_id,''))))''';
    return [
      for (final row in await _database.customSelect(sql).get())
        MediaFileMapper.toDomain(_database.mediaFiles.map(row.data)),
    ];
  }
}
