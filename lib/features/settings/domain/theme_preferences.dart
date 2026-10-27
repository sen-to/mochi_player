// 【偏好模型】记录主题模式与强调色的持久化标识。
// 不引用 Flutter 颜色类型，展示枚举的兼容回退由 Provider 处理。

class ThemePreferences {
  const ThemePreferences({this.modeIndex, this.accentIndex});
  final int? modeIndex;
  final int? accentIndex;
}
