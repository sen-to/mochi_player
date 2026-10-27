// 【通用界面】统一文字按钮、图标按钮、尺寸及忙碌状态。
// 组件负责交互反馈，操作结果由调用方处理。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mochi_player/core/ui/components/basic/app_appearance.dart';
import 'package:mochi_player/core/ui/theme/app_colors.dart';
import 'package:mochi_player/core/ui/theme/app_radii.dart';
import 'package:mochi_player/core/ui/theme/app_spacing.dart';
import 'package:mochi_player/core/ui/theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, ghost }

enum AppButtonSize { compact, regular, large }

/// 统一带文字和仅图标的应用按钮接口。
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.onPressed,
    required this.label,
    IconData? icon,
    this.variant = AppButtonVariant.primary,
    this.appearance = AppAppearance.standard,
    this.size = AppButtonSize.large,
    this.destructive = false,
    this.selected = false,
    this.accentColor,
    this.busy = false,
  }) : _leadingIcon = icon,
       _onlyIcon = null,
       tooltip = null;

  const AppButton.icon({
    super.key,
    required this.onPressed,
    required IconData icon,
    this.tooltip,
    this.variant = AppButtonVariant.secondary,
    this.selected = false,
    this.appearance = AppAppearance.standard,
    this.size = AppButtonSize.regular,
    this.accentColor,
  }) : label = '',
       _leadingIcon = null,
       _onlyIcon = icon,
       destructive = false,
       busy = false;

  final VoidCallback? onPressed;
  final String label;
  final IconData? _leadingIcon;
  final IconData? _onlyIcon;
  final String? tooltip;
  final AppButtonVariant variant;
  final AppAppearance appearance;
  final AppButtonSize size;
  final bool destructive;
  final bool selected;
  final Color? accentColor;
  final bool busy;

  bool get _iconOnly => _onlyIcon != null;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isHovering = false;
  bool _isFocused = false;

  bool get _enabled => widget.onPressed != null && !widget.busy;

  @override
  Widget build(BuildContext context) {
    final button = Semantics(
      button: true,
      enabled: _enabled,
      onTap: _enabled ? widget.onPressed : null,
      child: FocusableActionDetector(
        enabled: _enabled,
        mouseCursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onShowHoverHighlight: (value) => setState(() => _isHovering = value),
        onShowFocusHighlight: (value) => setState(() => _isFocused = value),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              if (_enabled) widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _enabled ? widget.onPressed : null,
          child: widget._iconOnly ? _buildIconButton(context) : _buildLabeledButton(context),
        ),
      ),
    );

    final tooltip = widget.tooltip;
    if (!widget._iconOnly || tooltip == null || tooltip.isEmpty) return button;
    return Tooltip(message: tooltip, child: button);
  }

  Widget _buildLabeledButton(BuildContext context) {
    final isPrimary = widget.variant == AppButtonVariant.primary;
    final metrics = _AppButtonMetrics.forSize(widget.size);
    final actionColor = widget.destructive
        ? AppColors.danger(context)
        : widget.accentColor ?? AppColors.primary(context);
    final adaptiveSurface = AppColors.controlSurface(context);
    final palette = _AppButtonPalette.resolve(
      context: context,
      actionColor: actionColor,
      isPrimary: isPrimary,
      isGhost: widget.variant == AppButtonVariant.ghost,
      isDestructive: widget.destructive,
      isOverlay: widget.appearance == AppAppearance.overlay,
      isSelected: widget.selected,
      adaptiveSurface: adaptiveSurface,
      adaptiveHoverSurface: Color.alphaBlend(AppColors.hoverSurface(context), adaptiveSurface),
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: _enabled ? 1 : 0.45,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: (_isHovering || _isFocused) && _enabled ? 1 : 0),
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        builder: (context, hoverProgress, child) {
          return Container(
            height: metrics.buttonHeight,
            padding: EdgeInsets.symmetric(horizontal: metrics.horizontalPadding),
            decoration: BoxDecoration(
              color: _enabled
                  ? Color.lerp(palette.restingBackground, palette.hoverBackground, hoverProgress)
                  : palette.disabledBackground,
              borderRadius: BorderRadius.circular(metrics.borderRadius),
              border: Border.all(color: Color.lerp(palette.restingBorder, palette.hoverBorder, hoverProgress)!),
              boxShadow: isPrimary && _enabled
                  ? [
                      BoxShadow(
                        color: actionColor.withAlpha((46 + (32 * hoverProgress)).round()),
                        blurRadius: 12 + (6 * hoverProgress),
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: child,
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.busy)
              SizedBox(
                width: metrics.iconSize,
                height: metrics.iconSize,
                child: CircularProgressIndicator(strokeWidth: 2, color: palette.foreground),
              )
            else if (widget._leadingIcon != null)
              Icon(
                widget._leadingIcon,
                size: metrics.iconSize,
                color: widget.selected ? actionColor : palette.foreground,
              ),
            if (widget.busy || widget._leadingIcon != null) const SizedBox(width: AppSpacing.xs),
            Text(widget.label, style: metrics.labelStyle.copyWith(color: palette.foreground)),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(BuildContext context) {
    final metrics = _AppButtonMetrics.forSize(widget.size);
    final selectedColor = widget.accentColor ?? AppColors.primary(context);
    final foreground = widget.selected
        ? selectedColor
        : widget.appearance == AppAppearance.overlay
        ? Colors.white.withAlpha(235)
        : AppColors.textPrimary(context).withAlpha(214);
    final usesOverlayAppearance = widget.appearance == AppAppearance.overlay;
    final isGhost = widget.variant == AppButtonVariant.ghost;
    final restingBackground = isGhost
        ? Colors.transparent
        : usesOverlayAppearance
        ? Colors.white.withAlpha(widget.selected ? 54 : 34)
        : widget.selected
        ? selectedColor.withAlpha(24)
        : AppColors.hoverSurface(context);
    final hoverBackground = isGhost
        ? AppColors.hoverSurface(context)
        : usesOverlayAppearance
        ? Colors.white.withAlpha(widget.selected ? 66 : 50)
        : widget.selected
        ? selectedColor.withAlpha(34)
        : Color.alphaBlend(AppColors.hoverSurface(context), restingBackground);
    final borderColor = isGhost
        ? Colors.transparent
        : widget.selected
        ? selectedColor.withAlpha(90)
        : usesOverlayAppearance
        ? Colors.white.withAlpha(56)
        : AppColors.separator(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(end: (_isHovering || _isFocused) && _enabled ? 1 : 0),
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      builder: (context, hoverProgress, child) {
        final background = Color.lerp(restingBackground, hoverBackground, hoverProgress)!;
        return Container(
          width: metrics.iconButtonSize,
          height: metrics.iconButtonSize,
          decoration: BoxDecoration(
            color: _enabled ? background : background.withAlpha(80),
            shape: BoxShape.circle,
            border: Border.all(color: borderColor),
          ),
          child: child,
        );
      },
      child: Icon(widget._onlyIcon, size: metrics.iconSize, color: foreground),
    );
  }
}

class _AppButtonMetrics {
  const _AppButtonMetrics({
    required this.buttonHeight,
    required this.iconButtonSize,
    required this.iconSize,
    required this.horizontalPadding,
    required this.borderRadius,
    required this.labelStyle,
  });

  final double buttonHeight;
  final double iconButtonSize;
  final double iconSize;
  final double horizontalPadding;
  final double borderRadius;
  final TextStyle labelStyle;

  factory _AppButtonMetrics.forSize(AppButtonSize size) => switch (size) {
    AppButtonSize.compact => const _AppButtonMetrics(
      buttonHeight: 30,
      iconButtonSize: 28,
      iconSize: 16,
      horizontalPadding: AppSpacing.md,
      borderRadius: AppRadii.control,
      labelStyle: AppTypography.controlLabel,
    ),
    AppButtonSize.regular => const _AppButtonMetrics(
      buttonHeight: 36,
      iconButtonSize: 36,
      iconSize: 19,
      horizontalPadding: AppSpacing.xl,
      borderRadius: AppRadii.surface,
      labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1),
    ),
    AppButtonSize.large => const _AppButtonMetrics(
      buttonHeight: 44,
      iconButtonSize: 44,
      iconSize: 22,
      horizontalPadding: AppSpacing.xl,
      borderRadius: AppRadii.surface,
      labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1),
    ),
  };
}

class _AppButtonPalette {
  const _AppButtonPalette({
    required this.restingBackground,
    required this.hoverBackground,
    required this.disabledBackground,
    required this.foreground,
    required this.restingBorder,
    required this.hoverBorder,
  });

  final Color restingBackground;
  final Color hoverBackground;
  final Color disabledBackground;
  final Color foreground;
  final Color restingBorder;
  final Color hoverBorder;

  factory _AppButtonPalette.resolve({
    required BuildContext context,
    required Color actionColor,
    required bool isPrimary,
    required bool isGhost,
    required bool isDestructive,
    required bool isOverlay,
    required bool isSelected,
    required Color adaptiveSurface,
    required Color adaptiveHoverSurface,
  }) {
    if (isPrimary) {
      return _AppButtonPalette(
        restingBackground: actionColor,
        hoverBackground: actionColor,
        disabledBackground: actionColor.withAlpha(90),
        foreground: Colors.white,
        restingBorder: Colors.transparent,
        hoverBorder: Colors.transparent,
      );
    }
    if (isGhost) {
      return _AppButtonPalette(
        restingBackground: Colors.transparent,
        hoverBackground: AppColors.hoverSurface(context),
        disabledBackground: Colors.transparent,
        foreground: AppColors.textPrimary(context).withAlpha(220),
        restingBorder: Colors.transparent,
        hoverBorder: Colors.transparent,
      );
    }
    if (isDestructive) {
      return _AppButtonPalette(
        restingBackground: AppColors.danger(context).withAlpha(14),
        hoverBackground: AppColors.danger(context).withAlpha(26),
        disabledBackground: AppColors.danger(context).withAlpha(14),
        foreground: AppColors.danger(context),
        restingBorder: AppColors.danger(context).withAlpha(128),
        hoverBorder: AppColors.danger(context).withAlpha(190),
      );
    }
    if (isOverlay) {
      return _AppButtonPalette(
        restingBackground: Colors.black.withAlpha(76),
        hoverBackground: Colors.black.withAlpha(100),
        disabledBackground: Colors.black.withAlpha(42),
        foreground: Colors.white.withAlpha(235),
        restingBorder: Colors.white.withAlpha(58),
        hoverBorder: Colors.white.withAlpha(92),
      );
    }
    if (isSelected) {
      return _AppButtonPalette(
        restingBackground: actionColor.withAlpha(28),
        hoverBackground: actionColor.withAlpha(42),
        disabledBackground: AppColors.hoverSurface(context),
        foreground: actionColor,
        restingBorder: actionColor.withAlpha(150),
        hoverBorder: actionColor.withAlpha(190),
      );
    }
    return _AppButtonPalette(
      restingBackground: adaptiveSurface,
      hoverBackground: adaptiveHoverSurface,
      disabledBackground: AppColors.hoverSurface(context),
      foreground: AppColors.textPrimary(context).withAlpha(220),
      restingBorder: AppColors.separator(context),
      hoverBorder: AppColors.separator(context),
    );
  }
}
