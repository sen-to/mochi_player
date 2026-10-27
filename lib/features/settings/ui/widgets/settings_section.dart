// 【设置布局】统一设置分区的标题、说明及内容间距。
// 只负责内容组合，不持有业务状态。

import 'package:flutter/material.dart';
import 'package:mochi_player/core/ui/theme/app_colors.dart';
import 'package:mochi_player/core/ui/theme/app_spacing.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, required this.title, required this.subtitle, required this.groups});

  /// 此标签页中相关设置卡片上方的标题。
  final String title;

  /// 说明此设置标签页的作用范围。
  final String subtitle;

  /// 视觉上独立的一组相关设置；通常由 [AppFormGroup] 提供卡片表面和行间分隔。
  final List<Widget> groups;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context)),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle, style: TextStyle(fontSize: 13, color: AppColors.textSecondary(context))),
        const SizedBox(height: AppSpacing.xxl),
        for (var index = 0; index < groups.length; index++) ...[
          if (index != 0) const SizedBox(height: AppSpacing.xl),
          groups[index],
        ],
      ],
    );
  }
}
