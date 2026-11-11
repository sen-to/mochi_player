// 【浮层界面】定义菜单与筛选面板共用的浮层外观。
// MenuStyle 与自绘面板都从这里取值，功能层不再单独设置阴影、边框或背景。

import 'package:flutter/material.dart';
import 'package:mochi_player/core/ui/theme/app_colors.dart';
import 'package:mochi_player/core/ui/theme/app_radii.dart';

/// 应用浮层的共享视觉规格：下拉菜单、筛选面板与文本右键菜单使用同一份定义。
abstract final class AppMenuSurface {
  /// 面板内容与边缘之间的内边距。
  static const double padding = 6;

  /// 悬浮层次；[blurRadius] 与 [shadowOffset] 决定阴影的扩散范围。
  static const double elevation = 8;
  static const double blurRadius = 18;
  static const Offset shadowOffset = Offset(0, 8);

  /// 所有浮层共用的圆角；不提供覆盖入口，避免菜单、筛选面板与右键菜单再次分叉。
  static const BorderRadius radius = BorderRadius.all(Radius.circular(AppRadii.control));

  /// 深色主题下背景与浮层的对比更弱，需要更重的阴影才能区分层次。
  static Color shadowColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? Colors.black.withAlpha(112) : Colors.black.withAlpha(28);
  }

  /// 自绘面板使用的阴影，与 [style] 生成的材料阴影保持同一强度。
  static BoxShadow boxShadow(BuildContext context) =>
      BoxShadow(color: shadowColor(context), blurRadius: blurRadius, offset: shadowOffset);

  /// 锚定浮层的菜单样式；只有 [padding] 可按内容尺寸调整，圆角统一。
  static MenuStyle style(
    BuildContext context, {
    EdgeInsetsGeometry padding = const EdgeInsets.all(AppMenuSurface.padding),
  }) {
    return MenuStyle(
      backgroundColor: WidgetStatePropertyAll(AppColors.menuSurface(context)),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      shadowColor: WidgetStatePropertyAll(shadowColor(context)),
      elevation: const WidgetStatePropertyAll(elevation),
      padding: WidgetStatePropertyAll(padding),
      side: WidgetStatePropertyAll(BorderSide(color: AppColors.separator(context))),
      shape: const WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: radius)),
    );
  }
}
