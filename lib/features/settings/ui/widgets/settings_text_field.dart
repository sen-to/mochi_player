// 【设置界面】统一设置表单的文本输入样式及提交交互。
// 校验与保存由表单入口负责。

import 'package:flutter/material.dart';
import 'package:mochi_player/core/ui/components/input/app_input.dart';
import 'package:mochi_player/core/ui/components/input/form/app_form_item.dart';
import 'package:mochi_player/core/ui/theme/app_colors.dart';
import 'package:mochi_player/core/ui/theme/app_control_metrics.dart';
import 'package:mochi_player/core/ui/theme/app_spacing.dart';
import 'package:mochi_player/core/ui/theme/app_typography.dart';

class SettingsTextField extends StatelessWidget {
  const SettingsTextField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType,
    this.inputSuffix,
    this.trailing,
    this.suffixText,
    this.maxWidth = AppControlMetrics.defaultFieldWidth,
    this.onFocusLost,
  });

  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final bool enabled;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? inputSuffix;
  final Widget? trailing;
  final String? suffixText;
  final double maxWidth;
  final VoidCallback? onFocusLost;

  @override
  Widget build(BuildContext context) {
    return AppFormItem(
      icon: icon,
      label: label,
      enabled: enabled,
      control: Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: AppInput(
                  controller: controller,
                  enabled: enabled,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  onFocusLost: onFocusLost,
                  textAlign: suffixText == null ? TextAlign.start : TextAlign.end,
                  suffix: inputSuffix,
                ),
              ),
              if (suffixText != null) ...[
                const SizedBox(width: AppControlMetrics.iconLabelGap),
                Text(suffixText!, style: AppTypography.formSuffix.copyWith(color: AppColors.textSecondary(context))),
              ],
              if (trailing != null) ...[const SizedBox(width: AppSpacing.xs), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}
