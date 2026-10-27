// 【持久化契约】定义主题模式与强调色偏好的读写。
// Provider 维护展示状态和写入顺序，具体偏好存储由 data 实现。

import 'package:mochi_player/features/settings/domain/theme_preferences.dart';

abstract interface class ThemePreferencesRepository {
  Future<ThemePreferences> load();
  Future<void> saveMode(int index);
  Future<void> saveAccent(int index);
}
