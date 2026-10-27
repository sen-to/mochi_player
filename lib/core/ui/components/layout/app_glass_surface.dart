// 【通用界面】统一浮层使用的模糊背景、边框和圆角。
// 只提供视觉容器，不处理业务交互。

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mochi_player/core/ui/theme/app_radii.dart';

class AppGlassSurface extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final Color color;
  final Color borderColor;
  final double blur;
  final EdgeInsetsGeometry? padding;

  const AppGlassSurface({
    super.key,
    required this.child,
    required this.color,
    required this.borderColor,
    required this.blur,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppRadii.surface)),
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        // 零半径模糊没有视觉效果，但背景过滤仍会逐帧增加图层与背景读取；禁用过滤以跳过这些工作，同时保持组件树稳定。
        enabled: blur > 0,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: borderRadius,
            border: Border.all(color: borderColor),
          ),
          child: padding == null ? child : Padding(padding: padding!, child: child),
        ),
      ),
    );
  }
}
