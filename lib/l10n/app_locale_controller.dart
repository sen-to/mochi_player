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

class AppLocaleController extends ChangeNotifier {
  static const preferenceKey = 'app_language';
  AppLanguage _language = AppLanguage.system;
  AppLanguage _persistedLanguage = AppLanguage.system;
  int _revision = 0;
  bool _stopping = false;
  Future<void> _pending = Future.value();
  Future<void> Function(Map<String, Object?> snapshot)? onChanged;

  AppLanguage get language => _language;

  Locale? get locale => _language == AppLanguage.system ? null : Locale(_language.name);

  Map<String, Object?> get snapshot => {'language': _language.name, 'revision': _revision};

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    _language = AppLanguage.parse(prefs.getString(preferenceKey));
    _persistedLanguage = _language;
    notifyListeners();
  }

  /// Main-window only. Publish immediately and serialize accepted writes.
  Future<void> setLanguage(AppLanguage language) {
    if (_stopping) return Future.value();
    if (_language == language && _persistedLanguage == language) return _pending;
    var notification = Future<void>.value();
    if (_language != language) {
      _language = language;
      _revision++;
      final next = snapshot;
      notifyListeners();
      notification = Future<void>.sync(
        () => onChanged?.call(next),
      ).catchError((Object error) => debugPrint('Player language synchronization failed: $error'));
    }
    final operation = _pending.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString(preferenceKey, language.name)) throw StateError('Language preference was not saved');
      _persistedLanguage = language;
    });
    final completion = Future.wait<void>([operation, notification]).then((_) {});
    _pending = completion.catchError((Object error) => debugPrint('Language preference update failed: $error'));
    return completion;
  }

  /// Child-window only. Never writes a cached app-settings snapshot to disk.
  void applySnapshot(Object? value) {
    if (_stopping || value is! Map) return;
    final revision = value['revision'];
    if (revision is! int || revision < _revision) return;
    _revision = revision;
    _language = AppLanguage.parse(value['language']);
    notifyListeners();
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
