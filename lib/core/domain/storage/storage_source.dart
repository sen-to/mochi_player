// 【共享模型】描述媒体源名称、地址、根目录及启用状态。
// 凭据另行保存，不与来源展示数据混合。

import 'package:mochi_player/core/domain/storage/storage_source_type.dart';

/// 用户配置的媒体存储位置；凭据另行保存，防止列出来源时泄漏到界面。
class StorageSource {
  final String id;
  final String name;
  final StorageSourceType type;
  final String endpoint;
  final String rootPath;
  final bool enabled;

  const StorageSource({
    required this.id,
    required this.name,
    required this.type,
    required this.endpoint,
    this.rootPath = '/',
    this.enabled = true,
  });

  /// 校验来源身份及必需字段，统一媒体根路径的规范形式。
  StorageSource normalized() {
    final root = rootPath.trim();
    final absolute = root.isEmpty || root == '/'
        ? '/'
        : root.startsWith('/')
        ? root
        : '/$root';
    return StorageSource(
      id: requireId(id),
      name: _required(name, 'name'),
      type: type,
      endpoint: _required(endpoint, 'endpoint'),
      rootPath: absolute.length > 1 && absolute.endsWith('/') ? absolute.substring(0, absolute.length - 1) : absolute,
      enabled: enabled,
    );
  }

  static String requireId(String value) => _required(value, 'sourceId');
  static String _required(String value, String name) {
    final normalized = value.trim();
    if (normalized.isEmpty) throw ArgumentError.value(value, name, 'must not be empty');
    return normalized;
  }

  StorageSource copyWith({String? name, String? endpoint, String? rootPath, bool? enabled}) {
    return StorageSource(
      id: id,
      name: name ?? this.name,
      type: type,
      endpoint: endpoint ?? this.endpoint,
      rootPath: rootPath ?? this.rootPath,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StorageSource &&
        other.id == id &&
        other.name == name &&
        other.type == type &&
        other.endpoint == endpoint &&
        other.rootPath == rootPath &&
        other.enabled == enabled;
  }

  @override
  int get hashCode => Object.hash(id, name, type, endpoint, rootPath, enabled);
}
