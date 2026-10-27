// 【偏好状态测试】验证主题写入失败后队列可继续，销毁后迟到读取不通知界面。
// 持久化使用可控契约替身，不依赖 SharedPreferences 插件或原生窗口。

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/app_failure.dart';
import 'package:mochi_player/features/settings/application/theme_preferences_repository.dart';
import 'package:mochi_player/features/settings/application/theme_provider.dart';
import 'package:mochi_player/features/settings/domain/theme_preferences.dart';

void main() {
  test('a late load preserves edited fields while restoring untouched preferences', () async {
    final repository = _Repository();
    final provider = ThemeProvider(repository: repository);
    addTearDown(provider.dispose);
    provider.setAccentColor(AppAccentColor.green);
    repository.loading.complete(
      ThemePreferences(modeIndex: ThemeMode.dark.index, accentIndex: AppAccentColor.red.index),
    );
    await Future<void>.delayed(Duration.zero);
    await provider.waitForPendingSave();
    expect(provider.themeMode, ThemeMode.dark);
    expect(provider.accentColor, AppAccentColor.green);
  });

  test('a failed save is reported without blocking later accepted writes', () async {
    final repository = _Repository();
    final provider = ThemeProvider(repository: repository);
    addTearDown(provider.dispose);
    repository.loading.complete(const ThemePreferences());
    await Future<void>.delayed(Duration.zero);
    provider.setTheme(ThemeMode.dark);
    await provider.waitForPendingSave();
    expect(provider.error, AppFailure.settingsSave);
    provider.setTheme(ThemeMode.light);
    await provider.waitForPendingSave();
    expect(repository.writes, [ThemeMode.dark.index, ThemeMode.light.index]);
    expect(provider.error, isNull);
  });
  test('disposing while loading detaches notifications and rejects new edits', () async {
    final repository = _Repository();
    final provider = ThemeProvider(repository: repository);
    var notifications = 0;
    provider.addListener(() => notifications++);
    provider.dispose();
    repository.loading.complete(const ThemePreferences(modeIndex: 1));
    await Future<void>.delayed(Duration.zero);
    provider.setTheme(ThemeMode.light);
    expect(notifications, 0);
    expect(repository.writes, isEmpty);
  });
}

class _Repository implements ThemePreferencesRepository {
  final loading = Completer<ThemePreferences>();
  final writes = <int>[];
  @override
  Future<ThemePreferences> load() => loading.future;
  @override
  Future<void> saveMode(int index) async {
    writes.add(index);
    if (writes.length == 1) throw StateError('write failed');
  }

  @override
  Future<void> saveAccent(int index) async {}
}
