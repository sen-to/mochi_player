// 【持久化契约】定义应用语言偏好的读取与保存。
// 语言状态管理不直接依赖偏好存储插件。

import 'package:mochi_player/l10n/domain/app_language.dart';

abstract interface class LanguagePreferencesRepository {
  /// 读取语言偏好；缺失或非法值返回 system，存储访问失败抛出异常。
  Future<AppLanguage> load();

  /// 保存用户选择的语言（包括 system），不把跟随系统解析成具体语言；失败抛出异常。
  Future<void> save(AppLanguage language);
}
