// 【持久化契约】定义媒体源配置、凭据及来源删除能力。
// 应用层只依赖此契约，数据库记录和字段转换留在 data。

import 'package:mochi_player/core/domain/storage/models.dart';

abstract interface class StorageSourceRepository {
  /// 按来源名称读取全部配置（含禁用来源），不在来源对象中返回密码；失败抛出异常。
  Future<List<StorageSource>> getAll();

  /// sourceId 去除首尾空白后不能为空；配置不存在返回 null，非法输入或读取失败抛出异常。
  Future<StorageSource?> getById(String sourceId);

  /// 校验并规范化来源后按 ID 新增 / 覆盖配置；credentials 为 null 会保存为空凭据。
  /// 不测试连接或通知页面，校验与存储失败抛出异常。
  Future<void> save(StorageSource source, {StorageCredentials? credentials});

  /// 来源不存在返回 null；已存在但未设置凭据时返回空用户名 / 密码，不等于来源不存在。
  Future<StorageCredentials?> readCredentials(String sourceId);

  /// 删除配置，并通过数据库级联删除其文件索引；不删除物理文件或共享元数据。
  /// true 表示来源存在并删除，false 表示原本不存在；失败抛出异常。
  Future<bool> delete(String sourceId);

  /// 原子删除来源及其文件索引，并返回删除的文件数；来源不存在返回 null。
  /// 不删除物理文件或共享元数据；sourceId 规则与 getById 一致，失败抛出异常。
  Future<int?> deleteWithMedia(String sourceId);
}
