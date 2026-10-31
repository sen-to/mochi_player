// 【数据访问】将主题偏好读写适配到 SharedPreferences。
// 存储键和持久化字段集中在数据层，不操作界面状态。

import 'package:mochi_player/features/settings/application/theme_preferences_repository.dart';
import 'package:mochi_player/features/settings/domain/theme_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemePreferencesRepositoryImpl implements ThemePreferencesRepository {
  static const _modeKey = 'theme_mode';
  static const _accentKey = 'accent_color';
  @override
  Future<ThemePreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ThemePreferences(modeIndex: prefs.getInt(_modeKey), accentIndex: prefs.getInt(_accentKey));
  }

  @override
  Future<void> saveMode(int index) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setInt(_modeKey, index)) throw StateError('Theme preference was not saved');
  }

  @override
  Future<void> saveAccent(int index) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setInt(_accentKey, index)) throw StateError('Accent preference was not saved');
  }
}
