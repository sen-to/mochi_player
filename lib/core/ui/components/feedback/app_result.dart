// 【通用界面】组合空状态、错误或完成结果的图标、说明与操作。
// 只展示状态，不发起业务请求。

import 'package:flutter/material.dart';
import 'package:mochi_player/core/ui/theme/app_colors.dart';
import 'package:mochi_player/core/ui/theme/app_radii.dart';
import 'package:mochi_player/core/ui/theme/app_spacing.dart';

enum AppResultStatus { empty, info, error }

class AppResult extends StatelessWidget {
  final AppResultStatus status;
  final String title;
  final String? subtitle;
  final Widget? icon;
  final Widget? extra;

  const AppResult({super.key, required this.status, required this.title, this.subtitle, this.icon, this.extra});

  @override
  Widget build(BuildContext context) {
    final appearance = _ResultAppearance.resolve(context, status);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ResultIconContainer(
                appearance: appearance,
                child: IconTheme(
                  data: IconThemeData(size: 32, color: appearance.color),
                  child: icon ?? Icon(appearance.icon),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.55,
                  ),
                ),
              ],
              if (extra != null) ...[const SizedBox(height: AppSpacing.xl), extra!],
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultIconContainer extends StatelessWidget {
  final _ResultAppearance appearance;
  final Widget child;

  const _ResultIconContainer({required this.appearance, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: appearance.backgroundColor,
        borderRadius: BorderRadius.circular(AppRadii.surface),
        border: Border.all(color: appearance.color.withAlpha(42)),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _ResultAppearance {
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _ResultAppearance({required this.icon, required this.color, required this.backgroundColor});

  factory _ResultAppearance.resolve(BuildContext context, AppResultStatus status) {
    return switch (status) {
      AppResultStatus.empty => _ResultAppearance(
        icon: Icons.inbox_outlined,
        color: AppColors.textSecondary(context),
        backgroundColor: AppColors.controlSurface(context),
      ),
      AppResultStatus.info => _ResultAppearance(
        icon: Icons.info_outline_rounded,
        color: AppColors.primary(context),
        backgroundColor: AppColors.controlSurface(context),
      ),
      AppResultStatus.error => _ResultAppearance(
        icon: Icons.close_rounded,
        color: AppColors.danger(context),
        backgroundColor: AppColors.controlSurface(context),
      ),
    };
  }
}
