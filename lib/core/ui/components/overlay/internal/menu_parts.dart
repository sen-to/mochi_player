// 【内部界面】提供菜单面板、选项行和触发区域的共享视觉实现。
// 供应用菜单组合使用，不承载具体业务动作。

import 'package:flutter/material.dart';
import 'package:mochi_player/core/ui/theme/app_colors.dart';
import 'package:mochi_player/core/ui/theme/app_control_metrics.dart';
import 'package:mochi_player/core/ui/theme/app_radii.dart';

/// 应用菜单共同使用的内部视觉面板。
class MenuPanel extends StatelessWidget {
  const MenuPanel({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final shadowColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.black.withAlpha(112)
        : Colors.black.withAlpha(28);
    return DefaultTextStyle(
      style: TextStyle(
        color: AppColors.textPrimary(context),
        fontSize: 13,
        fontWeight: FontWeight.w500,
        decoration: TextDecoration.none,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.menuSurface(context),
          borderRadius: BorderRadius.circular(AppRadii.control),
          border: Border.all(color: AppColors.separator(context)),
          boxShadow: [BoxShadow(color: shadowColor, blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(_menuPanelPadding),
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    );
  }
}

/// 应用菜单共同使用的内部可交互选项行。
class MenuOptionRow extends StatefulWidget {
  const MenuOptionRow({super.key, required this.onPressed, required this.child});

  final VoidCallback? onPressed;
  final Widget child;

  @override
  State<MenuOptionRow> createState() => _MenuOptionRowState();
}

class _MenuOptionRowState extends State<MenuOptionRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: enabled ? (_) => setState(() => _hovered = true) : null,
      onExit: enabled ? (_) => setState(() => _hovered = false) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AppControlMetrics.stateAnimationDuration,
          curve: Curves.easeOutCubic,
          height: _menuItemHeight,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: enabled && _hovered ? AppColors.hoverSurface(context) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.small),
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: enabled ? AppColors.textPrimary(context) : AppColors.textSecondary(context)),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// 下拉菜单内部使用的指针触发区域。
class MenuTriggerArea extends StatefulWidget {
  const MenuTriggerArea({super.key, required this.onPressed, required this.child});

  final VoidCallback? onPressed;
  final Widget child;

  @override
  State<MenuTriggerArea> createState() => _MenuTriggerAreaState();
}

class _MenuTriggerAreaState extends State<MenuTriggerArea> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final hoverColor = AppColors.hoverSurface(context);
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: enabled ? (_) => setState(() => _hovered = true) : null,
      onExit: enabled ? (_) => setState(() => _hovered = false) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: widget.onPressed,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: enabled && _hovered ? 1 : 0),
          duration: AppControlMetrics.stateAnimationDuration,
          curve: Curves.easeOutCubic,
          builder: (context, progress, child) => DecoratedBox(
            decoration: BoxDecoration(
              color: Color.lerp(hoverColor.withAlpha(0), hoverColor, progress),
              borderRadius: BorderRadius.circular(AppRadii.small),
            ),
            child: child,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

const double _menuItemHeight = 36;
const double _menuPanelPadding = 6;
