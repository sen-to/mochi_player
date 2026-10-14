import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/infrastructure/database/app_database.dart';
import 'package:mochi_player/core/infrastructure/database/database_service.dart';

abstract interface class StorageSourceRepository {
  Future<List<StorageSource>> getAll();

  Future<StorageSource?> getById(String sourceId);

  Future<void> save(StorageSource source, {StorageCredentials? credentials});

  Future<StorageCredentials?> readCredentials(String sourceId);

  Future<bool> delete(String sourceId);

  /// Deletes a source together with all indexed files that it owns.
  /// Returns the deleted file count, or `null` when the source does not exist.
  Future<int?> deleteWithMedia(String sourceId);
}

/// Persists source configuration in SQLite through DatabaseService.
class DatabaseStorageSourceRepository implements StorageSourceRepository {
  final DatabaseService _database;

  DatabaseStorageSourceRepository({DatabaseService? database}) : _database = database ?? DatabaseService();

  @override
  Future<List<StorageSource>> getAll() async {
    final rows = await _database.getStorageSources();
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<StorageSource?> getById(String sourceId) async {
    final row = await _database.getStorageSource(_required(sourceId, 'sourceId'));
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> save(StorageSource source, {StorageCredentials? credentials}) {
    return _database.saveStorageSource(
      StorageSourceRow(
        sourceId: _required(source.id, 'id'),
        name: _required(source.name, 'name'),
        type: source.type.name,
        endpoint: _required(source.endpoint, 'endpoint'),
        rootPath: _normalizeRootPath(source.rootPath),
        enabled: source.enabled,
        username: credentials?.username.trim() ?? '',
        password: credentials?.password ?? '',
      ),
    );
  }

  @override
  Future<StorageCredentials?> readCredentials(String sourceId) async {
    final row = await _database.getStorageSource(_required(sourceId, 'sourceId'));
    if (row == null) return null;
    return StorageCredentials(username: row.username, password: row.password);
  }

  @override
  Future<bool> delete(String sourceId) {
    return _database.deleteStorageSource(_required(sourceId, 'sourceId'));
  }

  @override
  Future<int?> deleteWithMedia(String sourceId) {
    return _database.deleteStorageSourceAndMediaFiles(_required(sourceId, 'sourceId'));
  }

  StorageSource _toDomain(StorageSourceRow row) {
    return StorageSource(
      id: row.sourceId,
      name: row.name,
      type: StorageSourceType.values.byName(row.type),
      endpoint: row.endpoint,
      rootPath: row.rootPath,
      enabled: row.enabled,
    );
  }

  String _required(String value, String name) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(value, name, 'must not be empty');
    }
    return normalized;
  }

  String _normalizeRootPath(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized == '/') return '/';
    final withLeadingSlash = normalized.startsWith('/') ? normalized : '/$normalized';
    return withLeadingSlash.endsWith('/')
        ? withLeadingSlash.substring(0, withLeadingSlash.length - 1)
        : withLeadingSlash;
  }
}
