import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 用于存储主题偏好的键
const String _themePrefKey = 'theme_mode';
const String _accentPrefKey = 'accent_color';

enum AppAccentColor {
  blue(Color(0xFF2F80ED)),
  green(Color(0xFF43B649)),
  purple(Color(0xFF7065A8)),
  orange(Color(0xFFF28C28)),
  red(Color(0xFFE94B64));

  const AppAccentColor(this.color);

  final Color color;
}

class ThemeProvider with ChangeNotifier {
  bool _shuttingDown = false;
  Future<void> _pendingSave = Future<void>.value();

  void beginShutdown() => _shuttingDown = true;

  Future<void> waitForPendingSave() => _pendingSave;

  void _persist(String key, int value) {
    _pendingSave = _pendingSave.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(key, value);
    });
  }

  ThemeMode _themeMode = ThemeMode.system; // 默认跟随系统
  AppAccentColor _accentColor = AppAccentColor.purple;

  ThemeMode get themeMode => _themeMode;

  AppAccentColor get accentColor => _accentColor;

  ThemeProvider() {
    _loadTheme();
  }

  // 从 SharedPreferences 加载主题设置
  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themePrefKey) ?? ThemeMode.system.index;
    _themeMode = ThemeMode.values.elementAtOrNull(themeIndex) ?? ThemeMode.system;
    final accentIndex = prefs.getInt(_accentPrefKey) ?? AppAccentColor.purple.index;
    _accentColor = AppAccentColor.values.elementAtOrNull(accentIndex) ?? AppAccentColor.purple;
    notifyListeners();
  }

  // 切换主题并保存到 SharedPreferences
  void setTheme(ThemeMode themeMode) {
    if (_shuttingDown || _themeMode == themeMode) return;

    _themeMode = themeMode;
    notifyListeners();

    _persist(_themePrefKey, themeMode.index);
  }

  void setAccentColor(AppAccentColor accentColor) {
    if (_shuttingDown || _accentColor == accentColor) return;

    _accentColor = accentColor;
    notifyListeners();

    _persist(_accentPrefKey, accentColor.index);
  }
}
