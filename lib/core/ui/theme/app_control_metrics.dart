// 【主题常量】定义输入、按钮等控件的高度和尺寸规格。
// 避免在各控件中重复定义相同尺寸。

abstract final class AppControlMetrics {
  static const double rowHeight = 46;
  static const double descriptiveRowHeight = 58;

  static const double iconSize = 17;
  static const double iconLabelGap = 6;
  static const double labelControlGap = 10;
  static const double labelWidth = 190;

  static const double defaultFieldWidth = 360;

  static const Duration stateAnimationDuration = Duration(milliseconds: 120);

  const AppControlMetrics._();
}
