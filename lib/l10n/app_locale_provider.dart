import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stored preference, distinct from the currently resolved system locale.
enum AppLanguage {
  system,
  zh,
  en;

  static AppLanguage parse(Object? value) => values.where((item) => item.name == value).firstOrNull ?? system;
}

class AppLocaleProvider extends ChangeNotifier {
  static const preferenceKey = 'app_language';
  AppLanguage _language = AppLanguage.system;
  AppLanguage _persistedLanguage = AppLanguage.system;
  bool _stopping = false;
  Future<void> _pending = Future.value();

  AppLanguage get language => _language;

  Locale? get locale => _language == AppLanguage.system ? null : Locale(_language.name);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    _language = AppLanguage.parse(prefs.getString(preferenceKey));
    _persistedLanguage = _language;
    notifyListeners();
  }

  /// All views observe this shared controller; accepted writes are serialized.
  Future<void> setLanguage(AppLanguage language) {
    if (_stopping) return Future.value();
    if (_language == language && _persistedLanguage == language) return _pending;
    if (_language != language) {
      _language = language;
      notifyListeners();
    }
    final operation = _pending.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString(preferenceKey, language.name)) throw StateError('Language preference was not saved');
      _persistedLanguage = language;
    });
    _pending = operation.catchError((Object error) => debugPrint('Language preference update failed: $error'));
    return operation;
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
