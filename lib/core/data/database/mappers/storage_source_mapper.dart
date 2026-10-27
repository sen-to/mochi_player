// 【持久化映射】转换媒体源数据库记录、业务来源和凭据。
// 业务来源不携带密码；业务字段遵循模型规范化规则，凭据编码留在数据边界。

import 'package:mochi_player/core/data/database/app_database.dart';
import 'package:mochi_player/core/domain/storage/models.dart';

abstract final class StorageSourceMapper {
  static StorageSource toDomain(StorageSourceDO row) => StorageSource(
    id: row.sourceId,
    name: row.name,
    type: StorageSourceType.values.byName(row.type),
    endpoint: row.endpoint,
    rootPath: row.rootPath,
    enabled: row.enabled,
  );

  static StorageSourceDO toDO(StorageSource source, StorageCredentials? credentials) {
    final normalized = source.normalized();
    return StorageSourceDO(
      sourceId: normalized.id,
      name: normalized.name,
      type: normalized.type.name,
      endpoint: normalized.endpoint,
      rootPath: normalized.rootPath,
      enabled: normalized.enabled,
      username: credentials?.username.trim() ?? '',
      password: credentials?.password ?? '',
    );
  }

  static StorageCredentials toCredentials(StorageSourceDO row) =>
      StorageCredentials(username: row.username, password: row.password);
}
