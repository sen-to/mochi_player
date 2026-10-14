import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/infrastructure/storage/storage_source_repository.dart';
import 'package:mochi_player/features/library/application/storage_sources_controller.dart';
import 'package:mochi_player/core/infrastructure/storage/storage_provider_registry.dart';

void main() {
  test('stores source configuration together with its credentials', () async {
    final repository = _MemorySourceRepository();
    final service = StorageSourcesController(
      repository: repository,
      registry: StorageProviderRegistry([]),
      onSourceRemoved: (_) {},
    );
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
    final service = StorageSourcesController(
      repository: repository,
      registry: StorageProviderRegistry([]),
      onSourceRemoved: (_) {},
    );
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
    final deleted = await service.deleteWithMedia(source.id);

    expect(deleted, 0);
    expect(await service.getAll(), isEmpty);
    expect(await service.readCredentials(source.id), isNull);
  });
  test('temporary connection closes after successful and failed directory reads', () async {
    for (final fails in [false, true]) {
      final connection = _Connection(fails: fails);
      final service = StorageSourcesController(
        repository: _MemorySourceRepository(),
        registry: StorageProviderRegistry([_Provider(connection)]),
        onSourceRemoved: (_) {},
      );
      if (fails) {
        await expectLater(service.testConnection(connection.source, null), throwsStateError);
      } else {
        expect(await service.testConnection(connection.source, null), 0);
      }
      expect(connection.closed, isTrue);
    }
  });
  test('shutdown rejects new requests and waits until accepted test connection is released', () async {
    final finishRead = Completer<List<StorageEntry>>();
    final connection = _Connection(pending: finishRead.future);
    final service = StorageSourcesController(
      repository: _MemorySourceRepository(),
      registry: StorageProviderRegistry([_Provider(connection)]),
      onSourceRemoved: (_) {},
    );
    final operation = service.testConnection(connection.source, null);
    await Future<void>.delayed(Duration.zero);
    service.beginShutdown();
    await expectLater(service.getAll(), throwsStateError);
    var drained = false;
    final draining = service.drain().then((_) => drained = true);
    await Future<void>.delayed(Duration.zero);
    expect(drained, isFalse);
    finishRead.complete([]);
    await operation;
    await draining;
    expect(connection.closed, isTrue);
  });
  test('source deletion notifies selection owner only after successful persistence', () async {
    final repository = _MemorySourceRepository();
    final removed = <String>[];
    final service = StorageSourcesController(
      repository: repository,
      registry: StorageProviderRegistry([]),
      onSourceRemoved: removed.add,
    );
    const source = StorageSource(id: 'nas', name: 'NAS', type: StorageSourceType.local, endpoint: '/media');
    await service.save(source);
    expect(await service.deleteWithMedia('nas'), 0);
    expect(await service.deleteWithMedia('missing'), isNull);
    expect(removed, ['nas']);
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

class _Provider implements StorageProvider {
  _Provider(this.connection);
  final _Connection connection;
  @override
  StorageSourceType get type => StorageSourceType.local;
  @override
  Future<StorageConnection> connect(StorageSource source, StorageCredentials? credentials) async => connection;
}

class _Connection implements StorageConnection {
  _Connection({this.fails = false, this.pending});
  final bool fails;
  final Future<List<StorageEntry>>? pending;
  bool closed = false;
  @override
  StorageSource get source =>
      const StorageSource(id: 'local', name: 'Local', type: StorageSourceType.local, endpoint: '/media');
  @override
  Future<List<StorageEntry>> readDirectory(String path) async {
    if (fails) throw StateError('unreadable');
    return pending ?? Future.value([]);
  }

  @override
  Future<bool> testConnection() async => true;
  @override
  Future<void> close() async {
    closed = true;
  }
}
