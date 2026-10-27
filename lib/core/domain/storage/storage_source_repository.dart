// 【持久化契约】定义媒体源配置、凭据及来源删除能力。
// 应用层只依赖此契约，数据库记录和字段转换留在 data。

import 'package:mochi_player/core/domain/storage/models.dart';

abstract interface class StorageSourceRepository {
  Future<List<StorageSource>> getAll();
  Future<StorageSource?> getById(String sourceId);
  Future<void> save(StorageSource source, {StorageCredentials? credentials});
  Future<StorageCredentials?> readCredentials(String sourceId);
  Future<bool> delete(String sourceId);

  /// 删除来源及其索引文件；来源不存在返回 null，否则返回删除文件数。
  Future<int?> deleteWithMedia(String sourceId);
}
