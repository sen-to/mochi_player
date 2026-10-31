// 【存储适配】将 WebDAV 目录查询转换为统一条目。
// 网络细节留在适配器内，调用方负责连接生命周期。

import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;

/// [WebDavStorageConnection] 所需的 WebDAV 客户端操作。
abstract interface class WebDavDirectoryClient {
  Future<List<webdav.File>> readDirectory(String path);
}

/// 连接 endpoint 已指向 WebDAV 根目录的来源。
class WebDavStorageAdapter implements StorageAdapter {
  @override
  StorageSourceType get type => StorageSourceType.webDav;

  @override
  Future<WebDavStorageConnection> connect(StorageSource source, StorageCredentials? credentials) async {
    if (source.type != type) {
      throw ArgumentError.value(source.type, 'source.type', 'must be $type');
    }

    final endpoint = source.endpoint.trim().replaceFirst(RegExp(r'/+$'), '');
    if (endpoint.isEmpty) {
      throw ArgumentError.value(source.endpoint, 'source.endpoint', 'must not be empty');
    }

    final client = webdav.newClient(
      endpoint,
      user: credentials?.username.trim() ?? '',
      password: credentials?.password ?? '',
      debug: false,
    );
    client.setConnectTimeout(10000);
    return WebDavStorageConnection(source: source, client: _WebDavClient(client));
  }
}

/// 使用来源相对路径的 [StorageConnection] 的 WebDAV 实现。
class WebDavStorageConnection implements StorageConnection {
  @override
  final StorageSource source;
  final WebDavDirectoryClient _client;

  WebDavStorageConnection({required this.source, required WebDavDirectoryClient client}) : _client = client {
    if (source.type != StorageSourceType.webDav) {
      throw ArgumentError.value(source.type, 'source.type', 'must be WebDAV');
    }
  }

  @override
  Future<List<StorageEntry>> readDirectory(String path) async {
    final files = await _client.readDirectory(_requestPathFor(path));
    return files
        .where((file) => file.name != null && file.name!.isNotEmpty)
        .map(
          (file) => StorageEntry(
            name: file.name!,
            isDirectory: file.isDir ?? false,
            size: file.size ?? 0,
            modifiedAt: file.mTime,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> close() async {}

  String _requestPathFor(String sourceRelativePath) {
    final rootPath = _normalizePath(source.rootPath);
    final path = _normalizePath(sourceRelativePath);
    if (path == '/') return rootPath;
    return rootPath == '/' ? path : '$rootPath$path';
  }

  String _normalizePath(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == '/') return '/';
    final withLeadingSlash = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return withLeadingSlash.endsWith('/')
        ? withLeadingSlash.substring(0, withLeadingSlash.length - 1)
        : withLeadingSlash;
  }
}

class _WebDavClient implements WebDavDirectoryClient {
  final webdav.Client _client;

  const _WebDavClient(this._client);

  @override
  Future<List<webdav.File>> readDirectory(String path) => _client.readDir(path);
}
