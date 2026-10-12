import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mochi_player/core/ui/components/basic/app_clickable_area.dart';
import 'package:mochi_player/core/ui/theme/app_colors.dart';
import 'package:mochi_player/core/ui/theme/app_control_metrics.dart';
import 'package:mochi_player/core/ui/theme/app_radii.dart';
import 'package:mochi_player/core/ui/theme/app_typography.dart';
import 'package:mochi_player/l10n/l10n.dart';

/// A bounded integer input with increment and decrement controls.
///
/// The value is controlled by the parent. The component owns its editing
/// controller and normalizes incomplete or out-of-range input on focus loss.
class AppInputNumber extends StatefulWidget {
  const AppInputNumber({
    super.key,
    required this.value,
    this.onChanged,
    this.min,
    this.max,
    this.step = 1,
    this.enabled = true,
  }) : assert(step > 0),
       assert(min == null || max == null || min <= max);

  final int value;
  final ValueChanged<int>? onChanged;
  final int? min;
  final int? max;
  final int step;
  final bool enabled;

  @override
  State<AppInputNumber> createState() => _AppInputNumberState();
}

class _AppInputNumberState extends State<AppInputNumber> {
  static const double _height = 32;
  static const double _buttonWidth = 36;

  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _hasFocus = false;

  bool get _isInteractive => widget.enabled && widget.onChanged != null;

  int get _normalizedValue => _clamp(widget.value);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _normalizedValue.toString());
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(AppInputNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      _setText(_normalizedValue);
    }
    if (oldWidget.enabled && !widget.enabled && _focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) _commitText();
    if (mounted) setState(() => _hasFocus = _focusNode.hasFocus);
  }

  void _handleTextChanged(String value) {
    final parsed = int.tryParse(value);
    if (parsed == null) return;
    final normalized = _clamp(parsed);
    if (normalized == widget.value) return;
    widget.onChanged?.call(normalized);
  }

  void _commitText() {
    final parsed = int.tryParse(_controller.text);
    final normalized = _clamp(parsed ?? widget.value);
    _setText(normalized);
    if (normalized != widget.value) widget.onChanged?.call(normalized);
  }

  void _adjust(int offset) {
    if (!_isInteractive) return;
    final next = _clamp(_normalizedValue + offset);
    if (next == _normalizedValue) return;
    _setText(next);
    widget.onChanged?.call(next);
  }

  int _clamp(int value) => value.clamp(widget.min ?? value, widget.max ?? value).toInt();

  void _setText(int value) {
    final text = value.toString();
    if (_controller.text == text) return;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary(context);
    final textColor = _isInteractive ? AppColors.textPrimary(context) : AppColors.textSecondary(context);
    final borderColor = _hasFocus ? primary.withAlpha(215) : AppColors.separator(context).withAlpha(90);
    final canDecrement = _isInteractive && (widget.min == null || _normalizedValue > widget.min!);
    final canIncrement = _isInteractive && (widget.max == null || _normalizedValue < widget.max!);

    return TweenAnimationBuilder<double>(
      tween: Tween(end: _hasFocus ? 1 : 0),
      duration: AppControlMetrics.stateAnimationDuration,
      curve: Curves.easeOut,
      builder: (context, focusProgress, child) => SizedBox(
        height: _height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _isInteractive ? AppColors.surface(context) : AppColors.subtleSurface(context),
            borderRadius: BorderRadius.circular(AppRadii.small),
            border: Border.all(
              color: Color.lerp(AppColors.separator(context).withAlpha(90), borderColor, focusProgress)!,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.small),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ),
      ),
      child: Row(
        children: [
          _StepperButton(
            icon: Icons.remove_rounded,
            tooltip: context.l10n.decrease,
            enabled: canDecrement,
            onPressed: () => _adjust(-widget.step),
          ),
          VerticalDivider(width: 1, color: AppColors.separator(context)),
          Expanded(
            child: CupertinoTextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: _isInteractive,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*$'))],
              onChanged: _handleTextChanged,
              onSubmitted: (_) => _commitText(),
              cursorColor: primary,
              cursorHeight: 16,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              padding: EdgeInsets.zero,
              style: AppTypography.formValue.copyWith(color: textColor),
              decoration: const BoxDecoration(color: Colors.transparent),
            ),
          ),
          VerticalDivider(width: 1, color: AppColors.separator(context)),
          _StepperButton(
            icon: Icons.add_rounded,
            tooltip: context.l10n.increase,
            enabled: canIncrement,
            onPressed: () => _adjust(widget.step),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.tooltip, required this.enabled, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: AppClickableArea(
        width: _AppInputNumberState._buttonWidth,
        height: _AppInputNumberState._height,
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.zero,
        hoverColor: AppColors.hoverSurface(context),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.textPrimary(context) : AppColors.textSecondary(context).withAlpha(90),
        ),
      ),
    );
  }
}
