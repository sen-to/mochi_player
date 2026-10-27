// 【通用界面】为整块区域提供点击、悬浮和键盘焦点反馈。
// 回调交给调用方执行，不负责导航或数据修改。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 让整个桌面区域可点击，并提供悬浮及键盘焦点反馈，不使用水波纹或按压高亮。
class AppClickableArea extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color hoverColor;
  final Color? borderColor;
  final double? width;
  final double? height;

  const AppClickableArea({
    super.key,
    required this.child,
    required this.borderRadius,
    required this.hoverColor,
    this.onTap,
    this.padding = EdgeInsets.zero,
    this.backgroundColor = Colors.transparent,
    this.borderColor,
    this.width,
    this.height,
  });

  @override
  State<AppClickableArea> createState() => _AppClickableAreaState();
}

class _AppClickableAreaState extends State<AppClickableArea> {
  bool _hovering = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    // 透明静止态与悬浮目标保持相同色彩空间；否则 ColorTween 从透明黑色插值，会让暗色模式中的浅色悬浮动画出现浑浊中间帧。
    final restingColor = widget.backgroundColor.a == 0 ? widget.hoverColor.withAlpha(0) : widget.backgroundColor;
    final hoverColor = widget.backgroundColor.a == 0
        ? widget.hoverColor
        : Color.alphaBlend(widget.hoverColor, widget.backgroundColor);
    final borderColor = widget.borderColor;

    return Semantics(
      button: enabled,
      enabled: enabled,
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: enabled ? (_) => setState(() => _hovering = true) : null,
        onExit: enabled ? (_) => setState(() => _hovering = false) : null,
        child: FocusableActionDetector(
          enabled: enabled,
          onShowFocusHighlight: (value) => setState(() => _focused = value),
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onTap?.call();
                return null;
              },
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: TweenAnimationBuilder<double>(
              // 动画只响应鼠标进入、离开和键盘焦点；外部选中状态变化立即生效。
              tween: Tween(end: enabled && (_hovering || _focused) ? 1 : 0),
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              builder: (context, hoverProgress, child) => Container(
                width: widget.width,
                height: widget.height,
                padding: widget.padding,
                decoration: BoxDecoration(
                  color: Color.lerp(restingColor, hoverColor, hoverProgress),
                  borderRadius: widget.borderRadius,
                  border: borderColor == null ? null : Border.all(color: borderColor),
                ),
                child: child,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
