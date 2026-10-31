// 【界面状态】维护主题模式与强调色并串行保存偏好。
// 应用共享此 Provider，不在页面中另建主题状态。

import 'package:flutter/material.dart';
import 'package:mochi_player/core/domain/app_failure.dart';
import 'package:mochi_player/features/settings/application/theme_preferences_repository.dart';

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
  bool _disposed = false;
  bool _themeChanged = false;
  bool _accentChanged = false;
  AppFailure? _error;
  AppFailure? get error => _error;
  Future<void> _pendingSave = Future<void>.value();

  void beginShutdown() => _shuttingDown = true;

  Future<void> waitForPendingSave() => _pendingSave;

  void _persist(Future<void> Function() write) {
    _pendingSave = _pendingSave.then((_) => write()).catchError((Object error) {
      debugPrint('主题偏好保存失败: $error');
      _error = AppFailure.settingsSave;
      if (!_disposed) notifyListeners();
    });
  }

  final ThemePreferencesRepository _repository;
  ThemeMode _themeMode = ThemeMode.system; // 默认跟随系统
  AppAccentColor _accentColor = AppAccentColor.purple;

  ThemeMode get themeMode => _themeMode;

  AppAccentColor get accentColor => _accentColor;

  ThemeProvider({required ThemePreferencesRepository repository}) : _repository = repository {
    _loadTheme();
  }

  // 迟到读取只恢复尚未修改的字段，避免覆盖用户刚选定的主题。
  Future<void> _loadTheme() async {
    try {
      final preferences = await _repository.load();
      if (_shuttingDown) return;
      final themeIndex = preferences.modeIndex ?? ThemeMode.system.index;
      if (!_themeChanged) _themeMode = ThemeMode.values.elementAtOrNull(themeIndex) ?? ThemeMode.system;
      final accentIndex = preferences.accentIndex ?? AppAccentColor.purple.index;
      if (!_accentChanged) _accentColor = AppAccentColor.values.elementAtOrNull(accentIndex) ?? AppAccentColor.purple;
    } catch (error) {
      _error = AppFailure.settingsLoad;
      debugPrint('主题偏好加载失败: $error');
    }
    if (!_shuttingDown) notifyListeners();
  }

  // 切换主题并按顺序保存偏好
  void setTheme(ThemeMode themeMode) {
    if (_shuttingDown || _themeMode == themeMode) return;

    _error = null;
    _themeChanged = true;
    _themeMode = themeMode;
    notifyListeners();

    _persist(() => _repository.saveMode(themeMode.index));
  }

  void setAccentColor(AppAccentColor accentColor) {
    if (_shuttingDown || _accentColor == accentColor) return;

    _error = null;
    _accentChanged = true;
    _accentColor = accentColor;
    notifyListeners();

    _persist(() => _repository.saveAccent(accentColor.index));
  }

  @override
  void dispose() {
    _disposed = true;
    beginShutdown();
    super.dispose();
  }
}
