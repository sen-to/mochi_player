import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mochi_player/core/ui/components/basic/app_button.dart';
import 'package:mochi_player/core/ui/theme/app_colors.dart';
import 'package:mochi_player/core/ui/theme/app_spacing.dart';
import 'package:window_manager/window_manager.dart';

class AppHeader extends StatelessWidget {
  static const double height = 60;

  final String title;
  final bool _showBackButton;
  final VoidCallback? onBack;
  final Widget? trailing;
  final double visibility;

  const AppHeader({super.key, required this.title, this.trailing, this.visibility = 1})
    : _showBackButton = false,
      onBack = null;

  const AppHeader.back({super.key, required this.title, this.onBack, this.trailing, this.visibility = 1})
    : _showBackButton = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clampedVisibility = visibility.clamp(0.0, 1.0).toDouble();
    final backgroundColor = AppColors.headerBackground(context);
    final backButton = _showBackButton
        ? AppButton.icon(
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            icon: Icons.arrow_back_rounded,
            tooltip: '返回',
            size: AppButtonSize.regular,
          )
        : null;

    return IgnorePointer(
      ignoring: clampedVisibility < 0.1,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: clampedVisibility,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: theme.platform == TargetPlatform.windows ? null : (_) => windowManager.startDragging(),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: height,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  border: Border(
                    bottom: BorderSide(
                      color: theme.dividerColor.withAlpha((255 * clampedVisibility).round()),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    if (backButton != null) ...[backButton, const SizedBox(width: 14)],
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                    if (trailing != null) ...[const SizedBox(width: 20), trailing!],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
