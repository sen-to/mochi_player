// 【通用界面】提供应用统一样式的布尔开关。
// 通过回调报告选择，不保存业务配置。

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mochi_player/core/ui/theme/app_colors.dart';

class AppSwitch extends StatelessWidget {
  static const double _width = 38;
  static const double _height = 24;

  final bool value;
  final ValueChanged<bool>? onChanged;

  const AppSwitch({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _width,
      height: _height,
      child: FittedBox(
        fit: BoxFit.contain,
        child: CupertinoSwitch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.primary(context),
          inactiveTrackColor: AppColors.separator(context),
          thumbColor: Colors.white,
        ),
      ),
    );
  }
}
