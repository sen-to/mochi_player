// 【存储适配】读取来源凭据、创建扫描连接并递归产出媒体快照。
// 协议资源封装在扫描会话中，读取不完整时报告失败标记。

import 'package:logger/logger.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/domain/storage/storage_adapter_registry.dart';
import 'package:mochi_player/core/domain/storage/storage_source_repository.dart';
import 'package:mochi_player/features/library/domain/media_file_kind.dart';
import 'package:mochi_player/features/library/sync/application/library_source_scanner.dart';
import 'package:mochi_player/features/library/sync/application/scanned_media_file_mapper.dart';
import 'package:mochi_player/features/library/sync/domain/media_filename_parser.dart';

/// 将凭据与协议连接细节隔离在同步编排之外。
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
  Future<LibrarySourceScanSession> open(StorageSource source) async {
    final credentials = await _repository.readCredentials(source.id);
    final connection = await _registry.connect(source, credentials);
    return _StorageLibrarySourceScanSession(connection);
  }
}

class _StorageLibrarySourceScanSession implements LibrarySourceScanSession {
  _StorageLibrarySourceScanSession(this._connection) : _scanner = StorageMediaScanner(_connection);

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

/// 使用已建立的连接和来源相对路径扫描文件。
class StorageMediaScanner {
  StorageMediaScanner(this._connection);

  final StorageConnection _connection;
  final _logger = Logger(printer: PrettyPrinter(methodCount: 0));
  bool _hadReadError = false;

  bool get hadReadError => _hadReadError;

  Stream<MediaFile> scan() async* {
    _hadReadError = false;
    await for (final entry in _recursivelyListFiles('/')) {
      final parsed = MediaFilenameParser.parse(fileName: entry.name, filePath: entry.path);
      yield ScannedMediaFileMapper.createFile(
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
        } else if (MediaFileClassifier.resolve(entry.name) == MediaFileKind.video) {
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
