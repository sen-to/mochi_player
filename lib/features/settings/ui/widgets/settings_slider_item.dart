// 【设置界面】组合设置项标签、滑块和数值说明。
// 数值变化通过回调交给调用方。

import 'package:flutter/material.dart';
import 'package:mochi_player/core/ui/components/input/app_slider.dart';
import 'package:mochi_player/core/ui/components/input/form/app_form_item.dart';
import 'package:mochi_player/core/ui/theme/app_colors.dart';
import 'package:mochi_player/core/ui/theme/app_typography.dart';

class SettingsSliderItem extends StatelessWidget {
  static const double _valueWidth = 36;

  const SettingsSliderItem({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.step,
    required this.displayValue,
    required this.onChanged,
    this.onChangeEnd,
    this.icon,
    this.enabled = true,
  });

  final String label;
  final IconData? icon;
  final double value;
  final double min;
  final double max;
  final double? step;
  final String displayValue;
  final bool enabled;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return AppFormItem(
      icon: icon,
      label: label,
      enabled: enabled,
      control: Row(
        children: [
          Expanded(
            child: AppSlider(
              value: value,
              min: min,
              max: max,
              step: step,
              tooltipFormatter: (_) => displayValue,
              onChanged: enabled ? onChanged : null,
              onChangeEnd: enabled ? onChangeEnd : null,
            ),
          ),
          SizedBox(
            width: _valueWidth,
            child: Text(
              displayValue,
              textAlign: TextAlign.end,
              style: AppTypography.formValueEmphasis.copyWith(color: AppColors.textPrimary(context)),
            ),
          ),
        ],
      ),
    );
  }
}
