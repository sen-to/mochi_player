// 【持久化契约】定义普通应用偏好的读取和保存。
// 数据存储及字段规范化由 data 实现，不与界面状态混合。

import 'package:mochi_player/features/settings/domain/app_settings.dart';

abstract interface class AppSettingsRepository {
  /// 读取普通偏好，缺失字段使用模型默认值；读取失败抛出异常。
  Future<AppSettings> load();

  /// 规范化并保存偏好，返回实际保存的值；不应用网络配置或通知界面。
  /// 保存失败抛出异常；多字段偏好写入不保证事务原子性。
  Future<AppSettings> save(AppSettings settings);
}
