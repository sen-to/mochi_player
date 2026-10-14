import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/infrastructure/storage/storage_adapter_registry.dart';

void main() {
  const source = StorageSource(
    id: 'source',
    name: 'Test source',
    type: StorageSourceType.webDav,
    endpoint: 'https://example.com/dav',
  );

  test('resolves a provider by storage source type', () async {
    final provider = _FakeStorageAdapter();
    final registry = StorageAdapterRegistry([provider]);

    final connection = await registry.connect(source, null);

    expect(connection, same(provider.connection));
    expect(registry.supports(StorageSourceType.webDav), isTrue);
    expect(registry.supports(StorageSourceType.smb), isFalse);
  });

  test('rejects unsupported storage source types', () {
    final registry = StorageAdapterRegistry(const []);

    expect(() => registry.adapterFor(StorageSourceType.smb), throwsA(isA<UnsupportedError>()));
  });
}

class _FakeStorageAdapter implements StorageAdapter {
  final connection = _FakeStorageConnection();

  @override
  StorageSourceType get type => StorageSourceType.webDav;

  @override
  Future<StorageConnection> connect(StorageSource source, StorageCredentials? credentials) async => connection;
}

class _FakeStorageConnection implements StorageConnection {
  @override
  final source = const StorageSource(
    id: 'source',
    name: 'Test source',
    type: StorageSourceType.webDav,
    endpoint: 'https://example.com/dav',
  );

  @override
  Future<List<StorageEntry>> readDirectory(String path) async => const [];

  @override
  Future<bool> testConnection() async => true;

  @override
  Future<void> close() async {}
}
