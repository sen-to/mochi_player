// 【界面状态】维护跟随系统、中文或英文的语言偏好，并串行保存选择。
// 应用共享此 Provider；系统实际语言与持久化偏好分别处理。

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mochi_player/l10n/application/language_preferences_repository.dart';
import 'package:mochi_player/l10n/domain/app_language.dart';

export 'package:mochi_player/l10n/domain/app_language.dart';

class AppLocaleProvider extends ChangeNotifier {
  AppLocaleProvider({required LanguagePreferencesRepository repository}) : _repository = repository;
  final LanguagePreferencesRepository _repository;
  AppLanguage _language = AppLanguage.system;
  AppLanguage _persistedLanguage = AppLanguage.system;
  bool _stopping = false;
  int _revision = 0;
  Future<void> _pending = Future.value();

  AppLanguage get language => _language;

  Locale? get locale => _language == AppLanguage.system ? null : Locale(_language.name);

  Future<void> load() async {
    if (_stopping) return;
    final revision = _revision;
    final language = await _repository.load();
    if (_stopping || revision != _revision) return;
    _language = language;
    _persistedLanguage = language;
    notifyListeners();
  }

  /// 所有视图共享此状态入口；已经接受的写入按顺序执行。
  Future<void> setLanguage(AppLanguage language) {
    if (_stopping) return Future.value();
    if (_language == language && _persistedLanguage == language) return _pending;
    if (_language != language) {
      _language = language;
      notifyListeners();
    }
    _revision++;
    final operation = _pending.then((_) async {
      await _repository.save(language);
      _persistedLanguage = language;
    });
    _pending = operation.catchError((Object error) => debugPrint('Language preference update failed: $error'));
    return operation;
  }

  @override
  void dispose() {
    beginShutdown();
    super.dispose();
  }

  void beginShutdown() => _stopping = true;

  Future<void> drain() => _pending;

  static Locale resolve(List<Locale>? preferred, Iterable<Locale> supported) {
    for (final locale in preferred ?? const <Locale>[]) {
      if (locale.languageCode == 'zh') return const Locale('zh');
      if (locale.languageCode == 'en') return const Locale('en');
    }
    return const Locale('en');
  }
}
