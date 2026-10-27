// 【路径规则】解析 SMB 共享名称及配置的媒体根路径。
// 只处理来源位置，不建立网络连接。

import 'package:mochi_player/core/domain/storage/storage_source.dart';
import 'package:path/path.dart' as path;

/// 解析后的 SMB 共享位置及配置的媒体根目录。
class SmbSourceLocation {
  const SmbSourceLocation({required this.host, required this.share, required this.rootPath});

  final String host;
  final String share;
  final String rootPath;

  factory SmbSourceLocation.fromSource(StorageSource source) {
    final endpoint = Uri.tryParse(source.endpoint.trim());
    if (endpoint == null || endpoint.scheme.toLowerCase() != 'smb' || endpoint.host.isEmpty) {
      throw ArgumentError.value(source.endpoint, 'source.endpoint', 'must be smb://host/share');
    }
    final segments = endpoint.pathSegments.where((segment) => segment.isNotEmpty).toList();
    if (segments.isEmpty) {
      throw ArgumentError.value(source.endpoint, 'source.endpoint', 'must include an SMB share name');
    }
    return SmbSourceLocation(host: endpoint.host, share: segments.first, rootPath: _normalizePath(source.rootPath));
  }

  /// 返回相对 SMB 共享根目录的路径。
  String resolve(String sourceRelativePath) {
    final requested = _normalizePath(sourceRelativePath);
    if (requested == '/') return rootPath == '/' ? '' : rootPath.substring(1);
    final joined = rootPath == '/' ? requested : '$rootPath$requested';
    return joined.replaceFirst(RegExp(r'^/+'), '');
  }

  static String normalizeRootPath(String value) => _normalizePath(value);

  static String _normalizePath(String value) {
    final normalized = path.posix.normalize('/${value.trim().replaceFirst(RegExp(r'^/+'), '')}');
    if (normalized == '.' || normalized == '/') return '/';
    if (normalized.startsWith('/../') || normalized == '/..') {
      throw ArgumentError.value(value, 'path', 'must stay inside the SMB share');
    }
    return normalized;
  }
}
