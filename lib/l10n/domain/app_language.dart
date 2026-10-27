// 【语言模型】定义持久化语言偏好及未知值的兼容回退。
// 语言标识与系统最终解析出的 Locale 分别表达。

enum AppLanguage {
  system,
  zh,
  en;

  static AppLanguage parse(Object? value) => values.where((item) => item.name == value).firstOrNull ?? system;
}
