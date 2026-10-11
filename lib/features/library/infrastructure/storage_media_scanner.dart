import 'package:logger/logger.dart';
import 'package:mochi_player/core/domain/storage/storage_connection.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/features/library/infrastructure/filename_parser.dart';
import 'package:mochi_player/features/library/infrastructure/media_file_metadata_mapper.dart';

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
