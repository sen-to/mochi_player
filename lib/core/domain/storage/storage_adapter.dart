import 'package:mochi_player/core/domain/storage/storage_connection.dart';
import 'package:mochi_player/core/domain/storage/storage_credentials.dart';
import 'package:mochi_player/core/domain/storage/storage_source.dart';
import 'package:mochi_player/core/domain/storage/storage_source_type.dart';

/// Creates a connection for one storage protocol.
abstract interface class StorageAdapter {
  StorageSourceType get type;

  Future<StorageConnection> connect(StorageSource source, StorageCredentials? credentials);
}
