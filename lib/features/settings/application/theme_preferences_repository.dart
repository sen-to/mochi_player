// 【持久化契约】定义主题模式与强调色偏好的读写。
// Provider 维护展示状态和写入顺序，具体偏好存储由 data 实现。

import 'package:mochi_player/features/settings/domain/theme_preferences.dart';

abstract interface class ThemePreferencesRepository {
  /// 返回已保存的主题索引；未设置字段为 null，默认值及非法索引回退由 Provider 决定。
  Future<ThemePreferences> load();

  /// 保存 ThemeMode 的枚举索引，不校验枚举范围；存储失败抛出异常。
  Future<void> saveMode(int index);

  /// 保存 AppAccentColor 的枚举索引，不校验枚举范围；存储失败抛出异常。
  Future<void> saveAccent(int index);
}
