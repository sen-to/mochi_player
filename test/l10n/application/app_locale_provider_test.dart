// 【行为测试】验证维护跟随系统、中文或英文的语言偏好，并串行保存选择。
// 测试对象的职责边界：应用共享此 Provider；系统实际语言与持久化偏好分别处理。

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/l10n/application/app_locale_provider.dart';
import 'package:mochi_player/l10n/application/language_preferences_repository.dart';
import 'package:mochi_player/l10n/data/language_preferences_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  test('a late load cannot replace a language selected while loading', () async {
    final repository = _DelayedLanguageRepository();
    final locales = AppLocaleProvider(repository: repository);
    addTearDown(locales.dispose);
    final loading = locales.load();
    await locales.setLanguage(AppLanguage.en);
    repository.loading.complete(AppLanguage.zh);
    await loading;
    expect(locales.language, AppLanguage.en);
    expect(repository.saved, [AppLanguage.en]);
  });
  test('a disposed provider ignores late reads and rejects new changes', () async {
    final repository = _DelayedLanguageRepository();
    final locales = AppLocaleProvider(repository: repository);
    var notifications = 0;
    locales.addListener(() => notifications++);
    final loading = locales.load();
    locales.dispose();
    repository.loading.complete(AppLanguage.zh);
    await loading;
    await locales.setLanguage(AppLanguage.en);
    expect(notifications, 0);
    expect(repository.saved, isEmpty);
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('resolves system languages with an explicit English fallback', () {
    const supported = [Locale('en'), Locale('zh')];
    expect(AppLocaleProvider.resolve([const Locale('fr'), const Locale('zh', 'TW')], supported), const Locale('zh'));
    expect(AppLocaleProvider.resolve([const Locale('en', 'US')], supported), const Locale('en'));
    expect(AppLocaleProvider.resolve([const Locale('ja')], supported), const Locale('en'));
    expect(AppLocaleProvider.resolve(null, supported), const Locale('en'));
  });

  test('missing and invalid preferences restore follow-system', () async {
    final locales = AppLocaleProvider(repository: LanguagePreferencesRepositoryImpl());
    await locales.load();
    expect(locales.language, AppLanguage.system);
    expect(locales.locale, isNull);
    SharedPreferences.setMockInitialValues({LanguagePreferencesRepositoryImpl.preferenceKey: 'unknown'});
    await locales.load();
    expect(locales.language, AppLanguage.system);
    locales.dispose();
  });

  test('persists choice, restores it and stores system rather than resolved language', () async {
    final locales = AppLocaleProvider(repository: LanguagePreferencesRepositoryImpl());
    await locales.load();
    await locales.setLanguage(AppLanguage.en);
    final restarted = AppLocaleProvider(repository: LanguagePreferencesRepositoryImpl());
    await restarted.load();
    expect(restarted.locale, const Locale('en'));
    await locales.setLanguage(AppLanguage.system);
    await restarted.load();
    expect(restarted.locale, isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(LanguagePreferencesRepositoryImpl.preferenceKey), 'system');
    locales.dispose();
    restarted.dispose();
  });

  test('rapid changes notify all views immediately and persist the final selection', () async {
    final locales = AppLocaleProvider(repository: LanguagePreferencesRepositoryImpl());
    final observed = <AppLanguage>[];
    locales.addListener(() => observed.add(locales.language));
    final first = locales.setLanguage(AppLanguage.en);
    final second = locales.setLanguage(AppLanguage.zh);
    expect(observed, [AppLanguage.en, AppLanguage.zh]);
    await Future.wait([first, second]);
    expect((await SharedPreferences.getInstance()).getString(LanguagePreferencesRepositoryImpl.preferenceKey), 'zh');
    locales.dispose();
  });

  test('shutdown drains accepted work and rejects new preference changes', () async {
    final locales = AppLocaleProvider(repository: LanguagePreferencesRepositoryImpl());
    final accepted = locales.setLanguage(AppLanguage.en);
    locales.beginShutdown();
    await locales.setLanguage(AppLanguage.zh);
    await locales.drain();
    await accepted;
    expect(locales.language, AppLanguage.en);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(LanguagePreferencesRepositoryImpl.preferenceKey), 'en');
    locales.dispose();
  });

  test('a failed save can retry the same language without publishing it twice', () async {
    final store = _FailOncePreferencesStore();
    SharedPreferencesStorePlatform.instance = store;
    final locales = AppLocaleProvider(repository: LanguagePreferencesRepositoryImpl());
    await locales.load();
    var notifications = 0;
    locales.addListener(() => notifications++);
    await expectLater(locales.setLanguage(AppLanguage.en), throwsStateError);
    expect(locales.language, AppLanguage.en);
    expect((await store.getAll())['flutter.app_language'], isNull);
    await locales.setLanguage(AppLanguage.en);
    expect((await store.getAll())['flutter.app_language'], 'en');
    expect(store.attempts, 2);
    expect(notifications, 1);
    final restarted = AppLocaleProvider(repository: LanguagePreferencesRepositoryImpl());
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

class _DelayedLanguageRepository implements LanguagePreferencesRepository {
  final loading = Completer<AppLanguage>();
  final saved = <AppLanguage>[];
  @override
  Future<AppLanguage> load() => loading.future;
  @override
  Future<void> save(AppLanguage language) async {
    saved.add(language);
  }
}
