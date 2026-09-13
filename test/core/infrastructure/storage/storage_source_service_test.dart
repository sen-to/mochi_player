import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/infrastructure/storage/storage_source_repository.dart';
import 'package:mochi_player/core/infrastructure/storage/storage_source_service.dart';

void main() {
  test('stores source configuration together with its credentials', () async {
    final repository = _MemorySourceRepository();
    final service = StorageSourceService(repository: repository);
    const source = StorageSource(
      id: 'home-nas',
      name: '家庭 NAS',
      type: StorageSourceType.webDav,
      endpoint: 'https://nas.example.com/dav',
    );
    const sourceCredentials = StorageCredentials(username: 'mochi', password: 'secret');

    await service.save(source, credentials: sourceCredentials);

    expect(await service.getAll(), [source]);
    expect(await service.readCredentials(source.id), sourceCredentials);
  });

  test('deletes source credentials with its source', () async {
    final repository = _MemorySourceRepository();
    final service = StorageSourceService(repository: repository);
    const source = StorageSource(
      id: 'home-nas',
      name: '家庭 NAS',
      type: StorageSourceType.webDav,
      endpoint: 'https://nas.example.com/dav',
    );

    await service.save(
      source,
      credentials: const StorageCredentials(username: 'mochi', password: 'secret'),
    );
    final deleted = await service.delete(source.id);

    expect(deleted, isTrue);
    expect(await service.getAll(), isEmpty);
    expect(await service.readCredentials(source.id), isNull);
  });
}

class _MemorySourceRepository implements StorageSourceRepository {
  final Map<String, StorageSource> _sources = {};
  final Map<String, StorageCredentials> _credentials = {};

  @override
  Future<bool> delete(String sourceId) async {
    final deleted = _sources.remove(sourceId) != null;
    if (deleted) _credentials.remove(sourceId);
    return deleted;
  }

  @override
  Future<int?> deleteWithMedia(String sourceId) async {
    return await delete(sourceId) ? 0 : null;
  }

  @override
  Future<List<StorageSource>> getAll() async => _sources.values.toList(growable: false);

  @override
  Future<StorageSource?> getById(String sourceId) async => _sources[sourceId];

  @override
  Future<StorageCredentials?> readCredentials(String sourceId) async => _credentials[sourceId];

  @override
  Future<void> save(StorageSource source, {StorageCredentials? credentials}) async {
    _sources[source.id] = source;
    if (credentials != null) _credentials[source.id] = credentials;
  }
}
