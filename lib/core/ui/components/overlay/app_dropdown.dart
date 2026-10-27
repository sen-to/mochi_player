// 【菜单界面】提供锚定触发控件的选项菜单。
// 候选项和动作由调用方定义，菜单负责浮层交互。

import 'package:flutter/material.dart';
import 'package:mochi_player/core/ui/components/overlay/internal/menu_parts.dart';
import 'package:mochi_player/core/ui/theme/app_colors.dart';
import 'package:mochi_player/core/ui/theme/app_icons.dart';
import 'package:mochi_player/core/ui/theme/app_radii.dart';

class AppDropdownOption<T> {
  const AppDropdownOption({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// 菜单锚定到触发控件时的水平对齐边缘。
enum AppDropdownMenuAlignment { start, end }

/// 通过指针触发、锚定控件的应用菜单。
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.trigger,
    required this.options,
    this.onSelected,
    this.selectedValue,
    this.tooltip,
    this.menuWidth = 160,
    this.menuAlignment = AppDropdownMenuAlignment.start,
  });

  final Widget trigger;
  final List<AppDropdownOption<T>> options;
  final ValueChanged<T>? onSelected;
  final T? selectedValue;
  final String? tooltip;
  final double menuWidth;
  final AppDropdownMenuAlignment menuAlignment;

  bool get _enabled => onSelected != null && options.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final shadowColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.black.withAlpha(112)
        : Colors.black.withAlpha(28);
    return MenuAnchor(
      consumeOutsideTap: true,
      useRootOverlay: true,
      clipBehavior: Clip.none,
      alignmentOffset: Offset(menuAlignment == AppDropdownMenuAlignment.end ? -menuWidth : 0, 6),
      style: MenuStyle(
        // MenuAnchor 的 bottomEnd 从触发控件尾端开始排列菜单；回移一个菜单宽度，使两者尾端真正对齐，并向前端展开。
        alignment: menuAlignment == AppDropdownMenuAlignment.start
            ? AlignmentDirectional.bottomStart
            : AlignmentDirectional.bottomEnd,
        backgroundColor: WidgetStatePropertyAll(AppColors.menuSurface(context)),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shadowColor: WidgetStatePropertyAll(shadowColor),
        elevation: const WidgetStatePropertyAll(8),
        // 菜单宽度与触发控件保持一致，避免桌面紧凑密度缩小固定宽度菜单。
        visualDensity: VisualDensity.standard,
        padding: const WidgetStatePropertyAll(EdgeInsets.all(6)),
        side: WidgetStatePropertyAll(BorderSide(color: AppColors.separator(context))),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppRadii.control))),
        ),
      ),
      menuChildren: [
        for (final option in options)
          SizedBox(
            width: menuWidth > 12 ? menuWidth - 12 : 0,
            child: _DropdownOptionRow<T>(
              option: option,
              selected: option.value == selectedValue,
              onPressed: () => onSelected?.call(option.value),
            ),
          ),
      ],
      builder: (context, controller, child) {
        final button = MenuTriggerArea(
          onPressed: _enabled ? () => controller.isOpen ? controller.close() : controller.open() : null,
          child: trigger,
        );
        final resolvedTooltip = tooltip;
        if (resolvedTooltip == null || resolvedTooltip.isEmpty) return button;
        return Tooltip(message: resolvedTooltip, excludeFromSemantics: true, child: button);
      },
    );
  }
}

class _DropdownOptionRow<T> extends StatelessWidget {
  const _DropdownOptionRow({required this.option, required this.selected, required this.onPressed});

  final AppDropdownOption<T> option;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.primary(context) : AppColors.textPrimary(context);
    return MenuOptionRow(
      onPressed: () {
        MenuController.maybeOf(context)?.close();
        onPressed();
      },
      child: Row(
        children: [
          if (option.icon != null) ...[Icon(option.icon, size: 15, color: foreground), const SizedBox(width: 8)],
          Expanded(
            child: Text(
              option.label,
              style: TextStyle(
                color: foreground,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          if (selected) Icon(AppIcons.check, size: 14, color: AppColors.primary(context)),
        ],
      ),
    );
  }
}
