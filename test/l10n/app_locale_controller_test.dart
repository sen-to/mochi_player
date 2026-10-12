import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/l10n/app_locale_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('resolves system languages with an explicit English fallback', () {
    const supported = [Locale('en'), Locale('zh')];
    expect(AppLocaleController.resolve([const Locale('fr'), const Locale('zh', 'TW')], supported), const Locale('zh'));
    expect(AppLocaleController.resolve([const Locale('en', 'US')], supported), const Locale('en'));
    expect(AppLocaleController.resolve([const Locale('ja')], supported), const Locale('en'));
    expect(AppLocaleController.resolve(null, supported), const Locale('en'));
  });

  test('missing and invalid preferences restore follow-system', () async {
    final locales = AppLocaleController();
    await locales.load();
    expect(locales.language, AppLanguage.system);
    expect(locales.locale, isNull);
    SharedPreferences.setMockInitialValues({AppLocaleController.preferenceKey: 'unknown'});
    await locales.load();
    expect(locales.language, AppLanguage.system);
    locales.dispose();
  });

  test('persists choice, restores it and stores system rather than resolved language', () async {
    final locales = AppLocaleController();
    await locales.load();
    await locales.setLanguage(AppLanguage.en);
    final restarted = AppLocaleController();
    await restarted.load();
    expect(restarted.locale, const Locale('en'));
    await locales.setLanguage(AppLanguage.system);
    await restarted.load();
    expect(restarted.locale, isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(AppLocaleController.preferenceKey), 'system');
    locales.dispose();
    restarted.dispose();
  });

  test('rapid changes publish immediately and child rejects a late older snapshot', () async {
    final main = AppLocaleController();
    final child = AppLocaleController();
    final firstNotice = Completer<void>();
    Map<String, Object?>? old;
    main.onChanged = (snapshot) async {
      if (snapshot['revision'] == 1) {
        old = snapshot;
        await firstNotice.future;
      }
      child.applySnapshot(snapshot);
    };
    final first = main.setLanguage(AppLanguage.en);
    final second = main.setLanguage(AppLanguage.zh);
    expect(main.language, AppLanguage.zh);
    expect(child.language, AppLanguage.zh);
    expect(old!['revision'], 1);
    firstNotice.complete();
    await Future.wait([first, second]);
    expect(child.language, AppLanguage.zh);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(AppLocaleController.preferenceKey), 'zh');
    main.dispose();
    child.dispose();
  });

  test('shutdown drains accepted work and rejects new preference changes', () async {
    final locales = AppLocaleController();
    final accepted = locales.setLanguage(AppLanguage.en);
    locales.beginShutdown();
    await locales.setLanguage(AppLanguage.zh);
    await locales.drain();
    await accepted;
    expect(locales.language, AppLanguage.en);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(AppLocaleController.preferenceKey), 'en');
    locales.dispose();
  });

  test('failed window notification does not poison later persistence', () async {
    final locales = AppLocaleController();
    locales.onChanged = (_) async => throw StateError('window disappeared');
    await locales.setLanguage(AppLanguage.en);
    locales.onChanged = null;
    await locales.setLanguage(AppLanguage.zh);
    expect((await SharedPreferences.getInstance()).getString(AppLocaleController.preferenceKey), 'zh');
    locales.dispose();
  });

  test('a failed save can retry the same language without publishing it twice', () async {
    final store = _FailOncePreferencesStore();
    SharedPreferencesStorePlatform.instance = store;
    final locales = AppLocaleController();
    await locales.load();
    var notifications = 0;
    locales.onChanged = (_) async => notifications++;
    await expectLater(locales.setLanguage(AppLanguage.en), throwsStateError);
    expect(locales.language, AppLanguage.en);
    expect((await store.getAll())['flutter.app_language'], isNull);
    await locales.setLanguage(AppLanguage.en);
    expect((await store.getAll())['flutter.app_language'], 'en');
    expect(store.attempts, 2);
    expect(notifications, 1);
    final restarted = AppLocaleController();
    await restarted.load();
    expect(restarted.language, AppLanguage.en);
    locales.dispose();
    restarted.dispose();
  });
}

class _FailOncePreferencesStore extends InMemorySharedPreferencesStore {
  _FailOncePreferencesStore() : super.empty();
  int attempts = 0;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (++attempts == 1) return false;
    return super.setValue(valueType, key, value);
  }
}
