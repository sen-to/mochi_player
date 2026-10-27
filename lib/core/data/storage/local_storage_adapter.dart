// 【存储适配】读取用户配置的本地目录及文件条目。
// 路径相对来源根目录解析，连接由浏览或扫描流程管理。

import 'dart:io';

import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:path/path.dart' as path;

/// 连接到用户选定的本地目录。
class LocalStorageAdapter implements StorageAdapter {
  @override
  StorageSourceType get type => StorageSourceType.local;

  @override
  Future<LocalStorageConnection> connect(StorageSource source, StorageCredentials? credentials) async {
    if (source.type != type) {
      throw ArgumentError.value(source.type, 'source.type', 'must be $type');
    }
    final directoryPath = source.endpoint.trim();
    if (directoryPath.isEmpty || !path.isAbsolute(directoryPath)) {
      throw ArgumentError.value(source.endpoint, 'source.endpoint', 'must be an absolute local directory path');
    }
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      throw FileSystemException('本地目录不存在或不可访问', directoryPath);
    }
    return LocalStorageConnection(source: source, directory: directory);
  }
}

/// 使用相对来源根目录路径的本地目录连接。
class LocalStorageConnection implements StorageConnection {
  LocalStorageConnection({required this.source, required Directory directory})
    : _rootPath = path.normalize(directory.absolute.path) {
    if (source.type != StorageSourceType.local) {
      throw ArgumentError.value(source.type, 'source.type', 'must be local');
    }
  }

  @override
  final StorageSource source;
  final String _rootPath;

  @override
  Future<List<StorageEntry>> readDirectory(String relativePath) async {
    final directory = Directory(_resolve(relativePath));
    final entities = await directory.list(followLinks: false).toList();
    final entries = <StorageEntry>[];
    for (final entity in entities) {
      final stat = await entity.stat();
      final isDirectory = stat.type == FileSystemEntityType.directory;
      if (!isDirectory && stat.type != FileSystemEntityType.file) continue;
      entries.add(
        StorageEntry(
          name: path.basename(entity.path),
          isDirectory: isDirectory,
          size: isDirectory ? 0 : stat.size,
          modifiedAt: stat.modified,
        ),
      );
    }
    return entries;
  }

  @override
  Future<bool> testConnection() async {
    try {
      await readDirectory('/');
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> close() async {}

  String _resolve(String relativePath) {
    final normalizedRelative = relativePath.replaceFirst(RegExp(r'^/+'), '').replaceAll('\\', path.separator);
    final resolved = path.normalize(path.join(_rootPath, normalizedRelative));
    if (resolved != _rootPath && !path.isWithin(_rootPath, resolved)) {
      throw ArgumentError.value(relativePath, 'relativePath', 'must stay inside the local source');
    }
    return resolved;
  }
}
