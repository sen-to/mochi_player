// 【通用界面】提供滑块、数值格式与悬浮提示的统一外观。
// 数值由调用方控制，组件只处理输入和展示。

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:mochi_player/core/ui/theme/app_colors.dart';
import 'package:mochi_player/l10n/l10n.dart';

typedef AppSliderValueFormatter = String Function(double value);

class AppSlider extends StatelessWidget {
  static const double _trackHeight = 3;
  static const double _thumbRadius = 6;
  static const double _hoverThumbRadius = 9;
  static const double _tooltipHitRadius = 16;
  static const double _tooltipGap = 10;

  const AppSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    this.step,
    this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.tooltipFormatter,
    this.semanticFormatterCallback,
  });

  final double value;
  final double min;
  final double max;

  /// 可选值之间的步长；省略时使用连续滑动。
  final double? step;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  final AppSliderValueFormatter? tooltipFormatter;
  final SemanticFormatterCallback? semanticFormatterCallback;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary(context);
    final thumbCenterColor = AppColors.controlSurface(context);
    final tooltipBackground = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF3A3A3C)
        : const Color(0xFF252527);

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: _trackHeight,
        activeTrackColor: primary,
        inactiveTrackColor: AppColors.separator(context),
        disabledActiveTrackColor: primary.withAlpha(90),
        disabledInactiveTrackColor: AppColors.separator(context).withAlpha(120),
        thumbColor: primary,
        disabledThumbColor: AppColors.textSecondary(context),
        overlayShape: const _SliderHoverOverlayShape(radius: _tooltipHitRadius),
        thumbShape: _AppSliderThumbShape(
          radius: _thumbRadius,
          hoverRadius: _hoverThumbRadius,
          centerColor: thumbCenterColor,
          tooltipBackground: tooltipBackground,
          tooltipGap: _tooltipGap,
        ),
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 1,
          decoration: TextDecoration.none,
        ),
        activeTickMarkColor: Colors.transparent,
        inactiveTickMarkColor: Colors.transparent,
        showValueIndicator: ShowValueIndicator.never,
      ),
      child: Slider(
        value: value,
        min: min,
        max: max,
        divisions: _divisionCount,
        label: tooltipFormatter?.call(value) ?? _formatValue(value, context.l10n.localeName),
        onChangeStart: onChanged == null ? null : onChangeStart,
        onChanged: onChanged,
        onChangeEnd: onChanged == null ? null : onChangeEnd,
        semanticFormatterCallback:
            semanticFormatterCallback ?? tooltipFormatter ?? (value) => _formatValue(value, context.l10n.localeName),
      ),
    );
  }

  int? get _divisionCount {
    final resolvedStep = step;
    if (resolvedStep == null) return null;
    if (resolvedStep <= 0) {
      throw ArgumentError.value(resolvedStep, 'step', '必须大于 0');
    }

    final intervalCount = (max - min) / resolvedStep;
    final roundedIntervalCount = intervalCount.round();
    if (roundedIntervalCount <= 0 || (intervalCount - roundedIntervalCount).abs() > 1e-9) {
      throw ArgumentError.value(resolvedStep, 'step', '必须能够整除 max - min');
    }
    return roundedIntervalCount;
  }

  String _formatValue(double value, String locale) => NumberFormat('0.##', locale).format(value);
}

class _SliderTooltipPainter {
  static const double _minimumWidth = 42;
  static const double _height = 28;
  static const double _arrowWidth = 12;
  static const double _arrowHeight = 6;

  static void paint(
    Canvas canvas, {
    required Offset center,
    required double opacity,
    required TextPainter labelPainter,
    required Color background,
    required double hoverRadius,
    required double tooltipGap,
  }) {
    if (opacity == 0) return;
    final width = (labelPainter.width + 20).clamp(_minimumWidth, 120.0).toDouble();
    final tip = center.translate(0, -hoverRadius - tooltipGap);
    final bubbleRect = Rect.fromLTWH(tip.dx - width / 2, tip.dy - _arrowHeight - _height, width, _height);
    final bubble = Path()
      ..addRRect(RRect.fromRectAndRadius(bubbleRect, const Radius.circular(8)))
      ..moveTo(tip.dx - _arrowWidth / 2, bubbleRect.bottom)
      ..lineTo(tip.dx + _arrowWidth / 2, bubbleRect.bottom)
      ..lineTo(tip.dx, tip.dy)
      ..close();
    final bounds = bubbleRect.inflate(16).expandToInclude(Rect.fromCircle(center: tip, radius: _arrowWidth));
    final needsOpacityLayer = opacity < 1;
    if (needsOpacityLayer) {
      canvas.saveLayer(bounds, Paint()..color = Colors.white.withValues(alpha: opacity));
    }
    canvas.drawShadow(bubble, Colors.black.withAlpha(70), 8, true);
    canvas.drawPath(bubble, Paint()..color = background);
    labelPainter.paint(
      canvas,
      Offset(bubbleRect.center.dx - labelPainter.width / 2, bubbleRect.center.dy - labelPainter.height / 2),
    );
    if (needsOpacityLayer) canvas.restore();
  }
}

class _SliderHoverOverlayShape extends SliderComponentShape {
  const _SliderHoverOverlayShape({required this.radius});

  final double radius;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(radius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {}
}

class _AppSliderThumbShape extends SliderComponentShape {
  const _AppSliderThumbShape({
    required this.radius,
    required this.hoverRadius,
    required this.centerColor,
    required this.tooltipBackground,
    required this.tooltipGap,
  });

  final double radius;
  final double hoverRadius;
  final Color centerColor;
  final Color tooltipBackground;
  final double tooltipGap;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(hoverRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final activeColor = sliderTheme.thumbColor ?? Colors.transparent;
    final disabledColor = sliderTheme.disabledThumbColor ?? activeColor;
    final color = Color.lerp(disabledColor, activeColor, enableAnimation.value)!;
    final interactionProgress = Curves.easeOut.transform(activationAnimation.value);
    final animatedRadius = radius + (hoverRadius - radius) * interactionProgress;
    final canvas = context.canvas;

    _SliderTooltipPainter.paint(
      canvas,
      center: center,
      opacity: interactionProgress,
      labelPainter: labelPainter,
      background: tooltipBackground,
      hoverRadius: hoverRadius,
      tooltipGap: tooltipGap,
    );

    if (interactionProgress > 0) {
      canvas.drawCircle(center, hoverRadius + 4, Paint()..color = color.withAlpha((35 * interactionProgress).round()));
    }
    canvas.drawCircle(center, animatedRadius, Paint()..color = color);
    if (interactionProgress > 0) {
      canvas.drawCircle(center, (hoverRadius - 4) * interactionProgress, Paint()..color = centerColor);
    }
  }
}
