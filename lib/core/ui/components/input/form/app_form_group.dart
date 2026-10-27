// 【表单布局】将相关表单项组合为连续的视觉分组。
// 接收外部控件，不持有业务数据。

import 'package:flutter/material.dart';
import 'package:mochi_player/core/ui/theme/app_colors.dart';
import 'package:mochi_player/core/ui/theme/app_radii.dart';
import 'package:mochi_player/core/ui/theme/app_spacing.dart';

/// 在连续的视觉表面中组合相关表单项。
class AppFormGroup extends StatelessWidget {
  const AppFormGroup({super.key, required this.children, this.title, this.trailing});

  /// 此设置卡片的可选标题。
  final String? title;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final separator = AppColors.separator(context);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: separator),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title case final title?) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ),
                  trailing ?? const SizedBox.shrink(),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: separator),
          ],
          for (var index = 0; index < children.length; index++) ...[
            if (index != 0)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.lg),
                child: Divider(height: 1, thickness: 1, color: separator),
              ),
            children[index],
          ],
        ],
      ),
    );
  }
}
