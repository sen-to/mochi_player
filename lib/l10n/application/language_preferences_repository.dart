// 【持久化契约】定义应用语言偏好的读取与保存。
// 语言状态管理不直接依赖偏好存储插件。

import 'package:mochi_player/l10n/domain/app_language.dart';

abstract interface class LanguagePreferencesRepository {
  Future<AppLanguage> load();
  Future<void> save(AppLanguage language);
}
