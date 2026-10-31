// 【数据访问】将语言偏好读写适配到 SharedPreferences。
// 保存失败显式报告，调用方可以保留重试状态。

import 'package:mochi_player/l10n/application/language_preferences_repository.dart';
import 'package:mochi_player/l10n/domain/app_language.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguagePreferencesRepositoryImpl implements LanguagePreferencesRepository {
  static const preferenceKey = 'app_language';
  @override
  Future<AppLanguage> load() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return AppLanguage.parse(prefs.getString(preferenceKey));
  }

  @override
  Future<void> save(AppLanguage language) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(preferenceKey, language.name)) throw StateError('Language preference was not saved');
  }
}
