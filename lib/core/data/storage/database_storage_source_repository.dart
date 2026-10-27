// 【共享数据访问】通过共享数据库实现媒体源配置和凭据的持久化操作。
// 业务联动由 StorageSourcesService 负责，仓库不通知页面。

import 'package:mochi_player/core/data/database/app_database.dart';
import 'package:mochi_player/core/data/database/mappers/storage_source_mapper.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/domain/storage/storage_source_repository.dart';

/// 通过 AppDatabase 将媒体源配置保存到 SQLite。
class DatabaseStorageSourceRepository implements StorageSourceRepository {
  final AppDatabase _database;

  DatabaseStorageSourceRepository({required AppDatabase database}) : _database = database;

  @override
  Future<List<StorageSource>> getAll() async {
    final rows = await _database.getStorageSources();
    return rows.map(StorageSourceMapper.toDomain).toList(growable: false);
  }

  @override
  Future<StorageSource?> getById(String sourceId) async {
    final row = await _database.getStorageSource(StorageSource.requireId(sourceId));
    return row == null ? null : StorageSourceMapper.toDomain(row);
  }

  @override
  Future<void> save(StorageSource source, {StorageCredentials? credentials}) {
    return _database.saveStorageSource(StorageSourceMapper.toDO(source, credentials));
  }

  @override
  Future<StorageCredentials?> readCredentials(String sourceId) async {
    final row = await _database.getStorageSource(StorageSource.requireId(sourceId));
    if (row == null) return null;
    return StorageSourceMapper.toCredentials(row);
  }

  @override
  Future<bool> delete(String sourceId) {
    return _database.deleteStorageSource(StorageSource.requireId(sourceId));
  }

  @override
  Future<int?> deleteWithMedia(String sourceId) {
    return _database.deleteStorageSourceAndMediaFiles(StorageSource.requireId(sourceId));
  }
}
