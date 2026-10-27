import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/infrastructure/database/app_database.dart';
import 'package:mochi_player/core/infrastructure/database/database_service.dart';
import 'package:mochi_player/core/infrastructure/database/sqlite_setup.dart';
import 'package:mochi_player/core/infrastructure/storage/storage_adapter_registry.dart';
import 'package:mochi_player/core/infrastructure/storage/storage_source_repository.dart';
import 'package:mochi_player/features/library/sync/storage_library_source_scanner.dart';

void main() {
  late DatabaseService database;
  late DatabaseStorageSourceRepository repository;
  late _Adapter adapter;
  late StorageLibrarySourceScanner scanner;
  const source = StorageSource(id: 'local', name: 'Local', type: StorageSourceType.local, endpoint: '/media');
  setUp(() async {
    database = DatabaseService.withDatabase(AppDatabase(NativeDatabase.memory(setup: configureSqlite)));
    await database.init();
    repository = DatabaseStorageSourceRepository(database: database);
    adapter = _Adapter();
    scanner = StorageLibrarySourceScanner(repository: repository, registry: StorageAdapterRegistry([adapter]));
  });
  tearDown(() => database.close());

  test('discovers only enabled sources supported by the registry', () async {
    await repository.save(source);
    await repository.save(
      const StorageSource(
        id: 'disabled',
        name: 'Disabled',
        type: StorageSourceType.local,
        endpoint: '/media',
        enabled: false,
      ),
    );
    await repository.save(
      const StorageSource(
        id: 'remote',
        name: 'Remote',
        type: StorageSourceType.webDav,
        endpoint: 'https://example.invalid/dav',
      ),
    );
    expect((await scanner.enabledSources()).map((source) => source.id), ['local']);
    expect(adapter.connection, isNull); // Listing sources must not open protocol connections.
  });

  test('resolves credentials internally, emits files, and releases a connection once', () async {
    await repository.save(
      source,
      credentials: const StorageCredentials(username: 'user', password: 'password'),
    );
    final scan = await scanner.open(source);
    expect(adapter.credentials!.username, 'user');
    expect(adapter.credentials!.password, 'password');
    final files = await scan.scan().toList();
    expect(files.single.sourceId, 'local');
    expect(files.single.path, '/Example.2020.mkv');
    expect(scan.hadReadError, isFalse);
    await Future.wait([scan.close(), scan.close()]);
    expect(adapter.connection!.closeCount, 1);
  });

  test('read failures remain observable to the cleanup policy', () async {
    await repository.save(source);
    adapter.failReads = true;
    final scan = await scanner.open(source);
    expect(await scan.scan().toList(), isEmpty);
    expect(scan.hadReadError, isTrue);
    await scan.close();
    expect(adapter.connection!.closeCount, 1);
  });
}

class _Adapter implements StorageAdapter {
  @override
  StorageSourceType get type => StorageSourceType.local;
  StorageCredentials? credentials;
  _Connection? connection;
  bool failReads = false;

  @override
  Future<StorageConnection> connect(StorageSource source, StorageCredentials? credentials) async {
    this.credentials = credentials;
    return connection = _Connection(source, failReads: failReads);
  }
}

class _Connection implements StorageConnection {
  _Connection(this.source, {required this.failReads});
  @override
  final StorageSource source;
  final bool failReads;
  int closeCount = 0;

  @override
  Future<List<StorageEntry>> readDirectory(String path) async {
    if (failReads) throw StateError('unreadable');
    return const [StorageEntry(name: 'Example.2020.mkv', isDirectory: false, size: 1024, modifiedAt: null)];
  }

  @override
  Future<bool> testConnection() async => !failReads;

  @override
  Future<void> close() async {
    closeCount++;
  }
}
