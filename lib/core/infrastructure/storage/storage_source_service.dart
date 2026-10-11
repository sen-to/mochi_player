import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/infrastructure/storage/storage_source_repository.dart';

/// Coordinates configured storage sources.
class StorageSourceService {
  final StorageSourceRepository _repository;

  StorageSourceService({StorageSourceRepository? repository})
    : _repository = repository ?? DatabaseStorageSourceRepository();

  Future<List<StorageSource>> getAll() => _repository.getAll();

  Future<StorageSource?> getById(String sourceId) => _repository.getById(sourceId);

  Future<void> save(StorageSource source, {StorageCredentials? credentials}) =>
      _repository.save(source, credentials: credentials);

  Future<StorageCredentials?> readCredentials(String sourceId) {
    return _repository.readCredentials(sourceId);
  }

  Future<bool> delete(String sourceId) => _repository.delete(sourceId);

  Future<int?> deleteWithMedia(String sourceId) => _repository.deleteWithMedia(sourceId);
}
