import 'package:flutter/material.dart';
import 'package:mochi_player/core/ui/theme/app_colors.dart';
import 'package:mochi_player/core/ui/theme/app_control_metrics.dart';
import 'package:mochi_player/core/ui/theme/app_spacing.dart';
import 'package:mochi_player/core/ui/theme/app_typography.dart';

/// Lays out one label, optional description, and its input control.
class AppFormItem extends StatelessWidget {
  const AppFormItem({
    super.key,
    required this.label,
    required this.control,
    this.icon,
    this.subtitle,
    this.subtitleColor,
    this.subtitleBelowControl = false,
    this.enabled = true,
    this.expandControl = true,
    this.labelWidth = AppControlMetrics.labelWidth,
    this.height,
  });

  final IconData? icon;
  final String label;
  final String? subtitle;
  final Color? subtitleColor;

  /// Shows supporting text across the full row, allowing it to wrap.
  final bool subtitleBelowControl;
  final Widget control;
  final bool enabled;
  final bool expandControl;
  final double? labelWidth;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final textColor = AppColors.textPrimary(context);
    final secondaryColor = AppColors.textSecondary(context);
    final resolvedHeight =
        height ?? (subtitle == null ? AppControlMetrics.rowHeight : AppControlMetrics.descriptiveRowHeight);
    final labelContent = _FormItemLabel(
      label: label,
      subtitle: subtitleBelowControl ? null : subtitle,
      textColor: enabled ? textColor : secondaryColor,
      secondaryColor: subtitleColor ?? (enabled ? secondaryColor : secondaryColor.withAlpha(190)),
    );

    final controlRow = Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: AppControlMetrics.iconSize, color: enabled ? secondaryColor : secondaryColor.withAlpha(170)),
          const SizedBox(width: AppControlMetrics.iconLabelGap),
        ],
        if (labelWidth == null) Expanded(child: labelContent) else SizedBox(width: labelWidth, child: labelContent),
        const SizedBox(width: AppControlMetrics.labelControlGap),
        if (expandControl) Expanded(child: control) else control,
      ],
    );

    if (subtitleBelowControl) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: height ?? AppControlMetrics.rowHeight),
              child: controlRow,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                subtitle!,
                style: AppTypography.formSupporting.copyWith(
                  color: subtitleColor ?? (enabled ? secondaryColor : secondaryColor.withAlpha(190)),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: resolvedHeight),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: subtitle == null ? 0 : AppSpacing.sm),
        child: controlRow,
      ),
    );
  }
}

class _FormItemLabel extends StatelessWidget {
  const _FormItemLabel({
    required this.label,
    required this.subtitle,
    required this.textColor,
    required this.secondaryColor,
  });

  final String label;
  final String? subtitle;
  final Color textColor;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.formLabel.copyWith(color: textColor),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(subtitle!, style: AppTypography.formSupporting.copyWith(color: secondaryColor)),
        ],
      ],
    );
  }
}
