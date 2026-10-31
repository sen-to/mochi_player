// 【偏好存储测试】验证插件返回失败时不会将保存报告为成功，后续可以重试。
// 使用内存偏好存储替身，不调用原生插件或真实网络。

import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/features/settings/data/app_settings_repository_impl.dart';
import 'package:mochi_player/features/settings/domain/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  test('a false write result rejects the save and permits a later retry', () async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() => SharedPreferences.setMockInitialValues({}));
    final store = _FailOncePreferencesStore();
    SharedPreferencesStorePlatform.instance = store;
    final repository = AppSettingsRepositoryImpl();
    const input = AppSettings(tmdbApiKey: 'new-key');
    await expectLater(repository.save(input), throwsStateError);
    expect(store.attempts, 1);
    expect((await store.getAll())['flutter.tmdb_api_key'], isNull);
    expect((await repository.save(input)).tmdbApiKey, 'new-key');
    expect((await store.getAll())['flutter.tmdb_api_key'], 'new-key');
  });
}

class _FailOncePreferencesStore extends InMemorySharedPreferencesStore {
  _FailOncePreferencesStore() : super.empty();
  int attempts = 0;

  @override
  Future<bool> setValue(String valueType, String key, Object value) {
    if (++attempts == 1) return Future.value(false);
    return super.setValue(valueType, key, value);
  }
}
