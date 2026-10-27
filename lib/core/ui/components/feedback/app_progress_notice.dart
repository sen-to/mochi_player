// 【通用界面】展示任务阶段、进度和完成数量。
// 进度由任务入口提供，组件不调度后台任务。

import 'package:flutter/material.dart';
import 'package:mochi_player/core/ui/theme/app_colors.dart';
import 'package:mochi_player/core/ui/theme/app_radii.dart';
import 'package:mochi_player/core/ui/theme/app_spacing.dart';

class AppProgressNotice extends StatelessWidget {
  const AppProgressNotice({super.key, required this.message, this.progress});

  final String message;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    return DefaultTextStyle.merge(
      style: const TextStyle(decoration: TextDecoration.none),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.compact, AppSpacing.md, AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.activitySurface(context),
          borderRadius: BorderRadius.circular(AppRadii.control),
          border: Border.all(color: theme.dividerColor),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 18, offset: const Offset(0, 10))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (progress == null) ...[
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: accentColor)),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  value: progress,
                  color: accentColor,
                  backgroundColor: theme.dividerColor.withAlpha(115),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
