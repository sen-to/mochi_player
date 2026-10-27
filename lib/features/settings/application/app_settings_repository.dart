// 【持久化契约】定义普通应用偏好的读取和保存。
// 数据存储及字段规范化由 data 实现，不与界面状态混合。

import 'package:mochi_player/features/settings/domain/app_settings.dart';

abstract interface class AppSettingsRepository {
  Future<AppSettings> load();
  Future<AppSettings> save(AppSettings settings);
}
