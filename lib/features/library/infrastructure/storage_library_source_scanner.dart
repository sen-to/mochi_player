import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/infrastructure/storage/storage_adapter_registry.dart';
import 'package:mochi_player/core/infrastructure/storage/storage_source_repository.dart';
import 'package:mochi_player/features/library/application/library_source_scanner.dart';
import 'package:mochi_player/features/library/infrastructure/storage_media_scanner.dart';

/// Keeps credentials and protocol connections outside synchronization orchestration.
class StorageLibrarySourceScanner implements LibrarySourceScanner {
  StorageLibrarySourceScanner({required StorageSourceRepository repository, required StorageAdapterRegistry registry})
    : _repository = repository,
      _registry = registry;

  final StorageSourceRepository _repository;
  final StorageAdapterRegistry _registry;

  @override
  Future<List<StorageSource>> enabledSources() async => (await _repository.getAll())
      .where((source) => source.enabled && _registry.supports(source.type))
      .toList(growable: false);

  @override
  Future<LibrarySourceScan> open(StorageSource source) async {
    final credentials = await _repository.readCredentials(source.id);
    final connection = await _registry.connect(source, credentials);
    return _StorageLibrarySourceScan(connection);
  }
}

class _StorageLibrarySourceScan implements LibrarySourceScan {
  _StorageLibrarySourceScan(this._connection) : _scanner = StorageMediaScanner(_connection);

  final StorageConnection _connection;
  final StorageMediaScanner _scanner;
  Future<void>? _closing;

  @override
  bool get hadReadError => _scanner.hadReadError;

  @override
  Stream<MediaFile> scan() => _scanner.scan();

  @override
  Future<void> close() => _closing ??= Future.sync(_connection.close);
}
