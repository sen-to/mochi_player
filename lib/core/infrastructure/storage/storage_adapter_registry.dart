import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/infrastructure/storage/local_storage_adapter.dart';
import 'package:mochi_player/core/infrastructure/storage/smb_storage_adapter.dart';
import 'package:mochi_player/core/infrastructure/storage/webdav_storage_adapter.dart';

/// Resolves the connection implementation for a configured storage protocol.
///
/// Consumers use this registry instead of checking [StorageSource.type]
/// themselves, so adding SMB or a local adapter only requires registering one
/// new [StorageAdapter].
class StorageAdapterRegistry {
  StorageAdapterRegistry(Iterable<StorageAdapter> adapters)
    : _adapters = {for (final adapter in adapters) adapter.type: adapter} {
    if (_adapters.length != adapters.length) {
      throw ArgumentError('A storage adapter may only be registered once per type.');
    }
  }

  factory StorageAdapterRegistry.defaults() =>
      StorageAdapterRegistry([LocalStorageAdapter(), WebDavStorageAdapter(), SmbStorageAdapter()]);

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
