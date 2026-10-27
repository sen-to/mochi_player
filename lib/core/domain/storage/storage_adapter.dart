// 【协议契约】定义某类存储协议的连接创建能力。
// 具体连接由适配器返回，使用者负责释放。

import 'package:mochi_player/core/domain/storage/storage_connection.dart';
import 'package:mochi_player/core/domain/storage/storage_credentials.dart';
import 'package:mochi_player/core/domain/storage/storage_source.dart';
import 'package:mochi_player/core/domain/storage/storage_source_type.dart';

/// 为一种存储协议创建连接。
abstract interface class StorageAdapter {
  StorageSourceType get type;

  Future<StorageConnection> connect(StorageSource source, StorageCredentials? credentials);
}
