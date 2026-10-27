// 【协议分派】按媒体源类型选择并建立存储连接。
// 调用方使用统一协议契约，不自行判断具体实现。

import 'package:mochi_player/core/domain/storage/models.dart';

/// 按配置的协议选择连接实现；调用方不自行判断 [StorageSource.type]，增加协议只需注册新的 [StorageAdapter]。
class StorageAdapterRegistry {
  StorageAdapterRegistry(Iterable<StorageAdapter> adapters)
    : _adapters = {for (final adapter in adapters) adapter.type: adapter} {
    if (_adapters.length != adapters.length) {
      throw ArgumentError('A storage adapter may only be registered once per type.');
    }
  }

  final Map<StorageSourceType, StorageAdapter> _adapters;

  bool supports(StorageSourceType type) => _adapters.containsKey(type);

  StorageAdapter adapterFor(StorageSourceType type) {
    final adapter = _adapters[type];
    if (adapter == null) {
      throw UnsupportedError('Storage type $type is not supported.');
    }
    return adapter;
  }

  Future<StorageConnection> connect(StorageSource source, StorageCredentials? credentials) {
    return adapterFor(source.type).connect(source, credentials);
  }
}
