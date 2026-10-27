// 【通用界面】展示可横向滚动的同级内容标签。
// 当前选项由调用方控制，不直接操作路由。

import 'package:flutter/material.dart';
import 'package:mochi_player/core/ui/components/basic/app_clickable_area.dart';
import 'package:mochi_player/core/ui/theme/app_colors.dart';
import 'package:mochi_player/core/ui/theme/app_control_metrics.dart';
import 'package:mochi_player/core/ui/theme/app_radii.dart';
import 'package:mochi_player/core/ui/theme/app_spacing.dart';

/// 描述 [AppTabs] 中一个可选择的同级目的地。
class AppTab<T> {
  const AppTab({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// 可横向滚动、由父级控制选中值的同级内容标签栏。
class AppTabs<T> extends StatelessWidget {
  static const double _height = 46;

  const AppTabs({
    super.key,
    required this.value,
    required this.tabs,
    required this.onChanged,
    this.minTabWidth = 132,
    this.indicatorWidth = 72,
  }) : assert(tabs.length > 1, 'AppTabs needs at least two tabs.'),
       assert(minTabWidth > 0),
       assert(indicatorWidth > 0);

  final T value;
  final List<AppTab<T>> tabs;
  final ValueChanged<T> onChanged;
  final double minTabWidth;
  final double indicatorWidth;

  @override
  Widget build(BuildContext context) {
    assert(tabs.any((tab) => tab.value == value), 'The selected value must belong to tabs.');
    final selectedIndex = tabs.indexWhere((tab) => tab.value == value);
    return LayoutBuilder(
      builder: (context, constraints) {
        final minimumWidth = minTabWidth * tabs.length;
        final fillsParent = constraints.hasBoundedWidth && constraints.maxWidth >= minimumWidth;
        final tabWidth = fillsParent ? constraints.maxWidth / tabs.length : minTabWidth;
        final contentWidth = fillsParent ? constraints.maxWidth : minimumWidth;
        final resolvedIndicatorWidth = indicatorWidth.clamp(0, tabWidth).toDouble();
        final borderColor = AppColors.separator(context);

        return DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: contentWidth,
              height: _height,
              child: Stack(
                children: [
                  Row(
                    children: [
                      for (final tab in tabs)
                        SizedBox(
                          width: tabWidth,
                          child: _AppTabButton<T>(
                            tab: tab,
                            selected: tab.value == value,
                            onPressed: () => onChanged(tab.value),
                          ),
                        ),
                    ],
                  ),
                  AnimatedPositioned(
                    duration: AppControlMetrics.stateAnimationDuration,
                    curve: Curves.easeOutCubic,
                    left: selectedIndex * tabWidth + (tabWidth - resolvedIndicatorWidth) / 2,
                    bottom: 0,
                    width: resolvedIndicatorWidth,
                    height: 2,
                    child: Container(key: const ValueKey('app_tabs_indicator'), color: AppColors.primary(context)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AppTabButton<T> extends StatelessWidget {
  const _AppTabButton({required this.tab, required this.selected, required this.onPressed});

  final AppTab<T> tab;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary(context);
    final foreground = selected ? primary : AppColors.textPrimary(context);
    return Center(
      child: Semantics(
        excludeSemantics: true,
        button: true,
        selected: selected,
        label: tab.label,
        onTap: onPressed,
        child: AppClickableArea(
          onTap: onPressed,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          borderRadius: BorderRadius.circular(AppRadii.control),
          hoverColor: AppColors.hoverSurface(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (tab.icon != null) ...[
                Icon(tab.icon, size: 18, color: foreground),
                const SizedBox(width: AppControlMetrics.iconLabelGap),
              ],
              Text(
                tab.label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
