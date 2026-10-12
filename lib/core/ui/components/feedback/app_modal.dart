import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mochi_player/core/ui/components/basic/app_button.dart';
import 'package:mochi_player/core/ui/theme/app_colors.dart';
import 'package:mochi_player/core/ui/theme/app_radii.dart';
import 'package:mochi_player/core/ui/theme/app_spacing.dart';
import 'package:mochi_player/l10n/l10n.dart';

abstract final class AppModal {
  static Future<bool?> confirm({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    IconData icon = Icons.help_outline_rounded,
    bool destructive = false,
  }) {
    return show(
      context: context,
      title: title,
      content: Text(
        message,
        style: TextStyle(
          color: AppColors.textSecondary(context),
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.55,
        ),
      ),
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      icon: icon,
      destructive: destructive,
    );
  }

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required Widget content,
    String? confirmLabel,
    String? cancelLabel,
    IconData? icon,
    bool destructive = false,
    bool showFooter = true,
    FutureOr<bool> Function()? onConfirm,
    bool barrierDismissible = true,
    double maxWidth = 440,
    double maxHeightFactor = 0.85,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: context.l10n.closeDialog,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                maxHeight: MediaQuery.sizeOf(dialogContext).height * maxHeightFactor,
              ),
              child: _ModalCard(
                title: title,
                content: content,
                icon: icon,
                destructive: destructive,
                showFooter: showFooter,
                confirmLabel: confirmLabel ?? dialogContext.l10n.confirm,
                cancelLabel: cancelLabel ?? dialogContext.l10n.cancel,
                onCancel: () => Navigator.of(dialogContext).pop(false),
                onConfirm: onConfirm == null
                    ? () => Navigator.of(dialogContext).pop(true)
                    : () async {
                        if (await onConfirm()) {
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop(true);
                          }
                        }
                      },
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutQuart,
          reverseCurve: Curves.easeInCubic,
        );

        return Stack(
          children: [
            Positioned.fill(
              child: FadeTransition(
                opacity: curvedAnimation,
                child: IgnorePointer(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                    child: ColoredBox(color: Colors.black.withAlpha(20)),
                  ),
                ),
              ),
            ),
            ScaleTransition(
              scale: Tween<double>(begin: 0.97, end: 1).animate(curvedAnimation),
              child: FadeTransition(opacity: curvedAnimation, child: child),
            ),
          ],
        );
      },
    );
  }

  const AppModal._();
}

class _ModalCard extends StatelessWidget {
  final String title;
  final Widget content;
  final IconData? icon;
  final bool destructive;
  final bool showFooter;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onCancel;
  final FutureOr<void> Function() onConfirm;

  const _ModalCard({
    required this.title,
    required this.content,
    required this.icon,
    required this.destructive,
    required this.showFooter,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? AppColors.danger(context) : AppColors.primary(context);
    final borderRadius = BorderRadius.circular(AppRadii.card);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.modalSurface(context),
        borderRadius: borderRadius,
        border: Border.all(color: AppColors.separator(context)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(28), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ModalTitle(title: title, icon: icon, accent: accent),
              const SizedBox(height: AppSpacing.lg),
              Flexible(child: content),
              if (showFooter) ...[
                const SizedBox(height: AppSpacing.xxl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 96,
                      child: AppButton(
                        onPressed: onCancel,
                        label: cancelLabel,
                        variant: AppButtonVariant.secondary,
                        size: AppButtonSize.compact,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    SizedBox(
                      width: 96,
                      child: AppButton(
                        onPressed: onConfirm,
                        label: confirmLabel,
                        destructive: destructive,
                        size: AppButtonSize.compact,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ModalTitle extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color accent;

  const _ModalTitle({required this.title, required this.icon, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: accent.withAlpha(24), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(icon, size: 17, color: accent),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}
