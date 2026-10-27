// 【表单界面】组合设置项标签、说明与布尔开关。
// 通过回调通知调用方，不直接访问设置 Provider。

import 'package:flutter/material.dart';
import 'package:mochi_player/core/ui/components/input/app_switch.dart';
import 'package:mochi_player/core/ui/components/input/form/app_form_item.dart';

class AppFormSwitchItem extends StatelessWidget {
  const AppFormSwitchItem({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.icon,
    this.enabled = true,
  });

  final String label;
  final String? subtitle;
  final IconData? icon;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppFormItem(
      icon: icon,
      label: label,
      subtitle: subtitle,
      enabled: enabled,
      labelWidth: null,
      expandControl: false,
      control: AppSwitch(value: value, onChanged: enabled ? onChanged : null),
    );
  }
}
