// 【协议契约】定义一个媒体源连接的目录读取和关闭能力。
// 传入路径相对来源根目录，连接所有者必须负责关闭。

import 'package:mochi_player/core/domain/storage/storage_entry.dart';
import 'package:mochi_player/core/domain/storage/storage_source.dart';

/// 已认证的媒体源连接；传入此接口的全部路径都相对 [source.rootPath]。
abstract interface class StorageConnection {
  StorageSource get source;

  Future<List<StorageEntry>> readDirectory(String path);

  Future<bool> testConnection();

  /// 释放此连接持有的协议专属资源。
  Future<void> close();
}
