// 【通用界面】统一文本输入框、焦点与文本编辑菜单。
// 组件管理编辑交互；校验规则和保存动作由表单负责。

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mochi_player/core/ui/components/input/internal/app_text_context_menu.dart';
import 'package:mochi_player/core/ui/theme/app_colors.dart';
import 'package:mochi_player/core/ui/theme/app_control_metrics.dart';
import 'package:mochi_player/core/ui/theme/app_radii.dart';
import 'package:mochi_player/core/ui/theme/app_spacing.dart';
import 'package:mochi_player/core/ui/theme/app_typography.dart';

enum _AppInputVariant { standard, search }

/// 应用表单及组合输入共同使用的文本输入框。
class AppInput extends StatefulWidget {
  const AppInput({
    super.key,
    required this.controller,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType,
    this.textAlign = TextAlign.start,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onFocusLost,
    this.inputFormatters,
    this.placeholder,
    this.prefix,
    this.suffix,
  }) : _variant = _AppInputVariant.standard;

  const AppInput.search({
    super.key,
    required this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.placeholder,
    this.prefix,
    this.suffix,
  }) : enabled = true,
       obscureText = false,
       keyboardType = null,
       textAlign = TextAlign.start,
       onFocusLost = null,
       inputFormatters = null,
       _variant = _AppInputVariant.search;

  final TextEditingController controller;
  final bool enabled;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextAlign textAlign;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onFocusLost;
  final List<TextInputFormatter>? inputFormatters;
  final String? placeholder;
  final Widget? prefix;
  final Widget? suffix;
  final _AppInputVariant _variant;

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  static const double _inputHeight = 26;
  static const double _searchTextTopPadding = 4;
  static const _searchTextStyle = TextStyle(fontSize: 14, height: 1);
  static const _searchStrutStyle = StrutStyle(fontSize: 14, height: 1, leading: 0, forceStrutHeight: true);

  late FocusNode _focusNode;
  late bool _ownsFocusNode;
  bool _wasFocused = false;

  @override
  void initState() {
    super.initState();
    _attachFocusNode(widget.focusNode);
  }

  @override
  void didUpdateWidget(AppInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _detachFocusNode();
      _attachFocusNode(widget.focusNode);
    }
    if (oldWidget.enabled && !widget.enabled && _focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _detachFocusNode();
    super.dispose();
  }

  void _attachFocusNode(FocusNode? focusNode) {
    _ownsFocusNode = focusNode == null;
    _focusNode = focusNode ?? FocusNode();
    if (!widget.enabled && _focusNode.hasFocus) {
      _focusNode.unfocus();
    }
    _wasFocused = _focusNode.hasFocus;
    _focusNode.addListener(_handleFocusChange);
  }

  void _detachFocusNode() {
    _focusNode.removeListener(_handleFocusChange);
    if (_ownsFocusNode) _focusNode.dispose();
  }

  void _handleFocusChange() {
    final hasFocus = _focusNode.hasFocus;
    if (_wasFocused && !hasFocus) widget.onFocusLost?.call();
    _wasFocused = hasFocus;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isSearch = widget._variant == _AppInputVariant.search;
    final primary = AppColors.primary(context);
    final textColor = widget.enabled ? AppColors.textPrimary(context) : AppColors.textSecondary(context);
    final surface = AppColors.surface(context);
    final controlBackground = AppColors.controlSurface(context);
    final focusedBorder = primary.withAlpha(isSearch ? 204 : 215);
    final restingBorder = isSearch
        ? Colors.transparent
        : widget.enabled
        ? focusedBorder.withAlpha(0)
        : AppColors.separator(context).withAlpha(90);
    final restingBackground = isSearch
        ? controlBackground
        : widget.enabled
        ? surface.withAlpha(0)
        : AppColors.subtleSurface(context);
    final focusedBackground = isSearch ? controlBackground : surface;
    final borderRadius = BorderRadius.circular(isSearch ? AppRadii.surface : AppRadii.small);

    return TweenAnimationBuilder<double>(
      tween: Tween(end: widget.enabled && _focusNode.hasFocus ? 1 : 0),
      duration: AppControlMetrics.stateAnimationDuration,
      curve: Curves.easeOut,
      builder: (context, focusProgress, child) {
        return SizedBox(
          height: isSearch ? 35 : _inputHeight,
          child: ClipRRect(
            borderRadius: borderRadius,
            clipBehavior: Clip.antiAlias,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color.lerp(restingBackground, focusedBackground, focusProgress),
                borderRadius: borderRadius,
                border: Border.all(
                  color: Color.lerp(restingBorder, focusedBorder, focusProgress)!,
                  width: isSearch ? 1.5 : 1,
                ),
              ),
              child: child,
            ),
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isSearch ? AppSpacing.compact : AppSpacing.sm),
        child: Row(
          children: [
            if (widget.prefix != null) ...[
              widget.prefix!,
              SizedBox(width: isSearch ? 8 : AppControlMetrics.iconLabelGap),
            ],
            Expanded(
              child: CupertinoTextField(
                controller: widget.controller,
                enabled: widget.enabled,
                focusNode: _focusNode,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                inputFormatters: widget.inputFormatters,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                contextMenuBuilder: AppTextContextMenu.buildForEditableText,
                cursorColor: primary,
                cursorHeight: 14,
                textAlign: widget.textAlign,
                textAlignVertical: TextAlignVertical.center,
                // 顶部内边距使中日韩字符的视觉中心下移 2 像素，同时保持行框居中；光标随文字一同移动。
                padding: EdgeInsets.only(top: isSearch ? _searchTextTopPadding : 0),
                // 使用稳定且紧凑的行框；缺少行高约束时，中日韩占位文字的后备字体可能引入不对称行距。
                strutStyle: isSearch ? _searchStrutStyle : null,
                placeholder: widget.placeholder,
                placeholderStyle: isSearch
                    ? _searchTextStyle.copyWith(color: AppColors.placeholderForeground(context))
                    : AppTypography.formValue.copyWith(color: AppColors.textSecondary(context)),
                style: isSearch
                    ? _searchTextStyle.copyWith(color: textColor)
                    : AppTypography.formValue.copyWith(color: textColor),
                // CupertinoTextField 在 decoration 为空时会绘制禁用背景；完整表面由 AppInput 管理，因此内部输入框始终保持透明。
                decoration: const BoxDecoration(color: Colors.transparent),
              ),
            ),
            if (widget.suffix != null) ...[
              SizedBox(width: isSearch ? 4 : AppControlMetrics.iconLabelGap),
              widget.suffix!,
            ],
          ],
        ),
      ),
    );
  }
}
