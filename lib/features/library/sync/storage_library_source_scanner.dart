import 'package:mochi_player/features/library/media_file_kind.dart';
import 'package:logger/logger.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/domain/storage/storage_connection.dart';
import 'package:mochi_player/core/infrastructure/storage/storage_adapter_registry.dart';
import 'package:mochi_player/core/infrastructure/storage/storage_source_repository.dart';
import 'package:mochi_player/features/library/sync/filename_parser.dart';
import 'package:mochi_player/features/library/sync/library_source_scanner.dart';
import 'package:mochi_player/features/library/sync/media_file_metadata_mapper.dart';

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

/// Scans an already-connected storage source using source-relative paths.
class StorageMediaScanner {
  StorageMediaScanner(this._connection);

  final StorageConnection _connection;
  final _logger = Logger(printer: PrettyPrinter(methodCount: 0));
  bool _hadReadError = false;

  bool get hadReadError => _hadReadError;

  Stream<MediaFile> scan() async* {
    _hadReadError = false;
    await for (final entry in _recursivelyListFiles('/')) {
      final parsed = FilenameParser.parse(fileName: entry.name, filePath: entry.path);
      yield MediaFileMetadataMapper.createFile(
        sourceId: _connection.source.id,
        path: entry.path,
        fileName: entry.name,
        size: entry.size,
        metadata: parsed,
      );
    }
  }

  Stream<_ScannedStorageFile> _recursivelyListFiles(String path) async* {
    try {
      final entries = await _connection.readDirectory(path);
      for (final entry in entries) {
        if (entry.name.isEmpty || entry.name.startsWith('.')) continue;
        final itemPath = _joinPath(path, entry.name, isDirectory: entry.isDirectory);
        if (entry.isDirectory) {
          yield* _recursivelyListFiles(itemPath);
        } else if (MediaFileKindResolver.resolve(entry.name) == MediaFileKind.video) {
          yield _ScannedStorageFile(name: entry.name, path: itemPath, size: entry.size);
        }
      }
    } catch (error) {
      _hadReadError = true;
      _logger.w('扫描来源 ${_connection.source.name} 的路径失败: $path - $error');
    }
  }

  String _joinPath(String directoryPath, String name, {required bool isDirectory}) {
    final base = directoryPath == '/' ? '/' : '${directoryPath.replaceFirst(RegExp(r'/+$'), '')}/';
    final path = '$base${name.replaceAll(RegExp(r'^/+|/+$'), '')}';
    return isDirectory ? '$path/' : path;
  }
}

class _ScannedStorageFile {
  const _ScannedStorageFile({required this.name, required this.path, required this.size});

  final String name;
  final String path;
  final int size;
}
