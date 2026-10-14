import 'package:mochi_player/core/domain/storage/storage_source.dart';
import 'package:path/path.dart' as path;

/// Parsed location of one SMB share and its configured media root.
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

  /// Returns a path relative to the SMB share.
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
