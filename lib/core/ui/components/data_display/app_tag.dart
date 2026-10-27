// 【通用界面】展示紧凑的评分、分类或描述标签。
// 只接收外部文本与样式。

import 'package:flutter/material.dart';
import 'package:mochi_player/core/ui/components/basic/app_appearance.dart';
import 'package:mochi_player/core/ui/theme/app_colors.dart';
import 'package:mochi_player/core/ui/theme/app_radii.dart';
import 'package:mochi_player/core/ui/theme/app_spacing.dart';

/// 展示简短的描述性元信息。
class AppTag extends StatelessWidget {
  const AppTag({
    super.key,
    required this.text,
    this.icon,
    this.appearance = AppAppearance.standard,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.outlined = true,
  });

  final String text;
  final IconData? icon;
  final AppAppearance appearance;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final usesOverlayAppearance = appearance == AppAppearance.overlay;
    final foreground =
        foregroundColor ?? (usesOverlayAppearance ? Colors.white : AppColors.textPrimary(context).withAlpha(220));

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.compact),
      decoration: BoxDecoration(
        color:
            backgroundColor ?? (usesOverlayAppearance ? Colors.white.withAlpha(42) : AppColors.controlSurface(context)),
        borderRadius: BorderRadius.circular(AppRadii.tag),
        border: outlined
            ? Border.all(
                color:
                    borderColor ?? (usesOverlayAppearance ? Colors.white.withAlpha(44) : AppColors.separator(context)),
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 15, color: foreground), const SizedBox(width: 4)],
          Text(
            text,
            style: TextStyle(color: foreground, fontSize: 12, fontWeight: FontWeight.w800, height: 1),
          ),
        ],
      ),
    );
  }
}
