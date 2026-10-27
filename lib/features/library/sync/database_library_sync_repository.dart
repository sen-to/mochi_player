import 'package:drift/drift.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/infrastructure/database/app_database.dart';
import 'package:mochi_player/core/infrastructure/database/database_service.dart';
import 'package:mochi_player/features/library/sync/library_sync_repository.dart';

class DatabaseLibrarySyncRepository implements LibrarySyncRepository {
  DatabaseLibrarySyncRepository({required DatabaseService database}) : _database = database;

  final DatabaseService _database;
  AppDatabase get _db => _database.database;

  @override
  Future<void> saveScannedFiles(List<MediaFile> files) => _database.saveScannedFiles(files);

  @override
  Future<Set<String>> sourcePaths(String sourceId) async {
    final query = _db.selectOnly(_db.mediaFiles)
      ..addColumns([_db.mediaFiles.path])
      ..where(_db.mediaFiles.sourceId.equals(sourceId));
    return (await query.get()).map((row) => row.read(_db.mediaFiles.path)!).toSet();
  }

  @override
  Future<int> removeMissingFiles(String sourceId, Set<String> seen) async {
    final missing = (await sourcePaths(sourceId)).difference(seen).toList();
    var deleted = 0;
    await _db.transaction(() async {
      for (var i = 0; i < missing.length; i += 400) {
        deleted += await (_db.delete(
          _db.mediaFiles,
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
    return [for (final row in await _db.customSelect(sql).get()) _db.mediaFiles.map(row.data)];
  }
}
