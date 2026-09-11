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
        // A zero-radius blur is visually a no-op, but the backdrop filter still
        // costs a layer and a backdrop read on every frame. Disabling it skips
        // that work while keeping the element tree stable.
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
