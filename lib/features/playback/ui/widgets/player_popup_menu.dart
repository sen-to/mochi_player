// 【播放器界面】提供锚定控制栏的菜单、选项行与开关。
// 管理菜单浮层与交互，具体选轨等动作由调用方处理。

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mochi_player/core/ui/components/basic/app_clickable_area.dart';
import 'package:mochi_player/core/ui/components/input/app_switch.dart';
import 'package:mochi_player/core/ui/theme/app_colors.dart';
import 'package:mochi_player/core/ui/theme/app_radii.dart';

abstract final class PlayerPopupMenuMetrics {
  static const double itemHeight = 40;
  static const double panelRadius = AppRadii.card;
  static const double gapFromButton = 8;
}

/// 在控制栏按钮上方锚定播放器菜单；使用自有玻璃表面、悬浮交互及紧凑尺寸，不使用 Material 的 [PopupMenuButton]。
class PlayerPopupMenuButton extends StatefulWidget {
  final Widget child;
  final double menuWidth;
  final Widget Function(BuildContext context, VoidCallback close) menuBuilder;
  final ValueChanged<bool>? onVisibilityChanged;

  const PlayerPopupMenuButton({
    super.key,
    required this.child,
    required this.menuWidth,
    required this.menuBuilder,
    this.onVisibilityChanged,
  });

  @override
  State<PlayerPopupMenuButton> createState() => _PlayerPopupMenuButtonState();
}

class _PlayerPopupMenuButtonState extends State<PlayerPopupMenuButton> with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _entry;
  bool _isClosing = false;
  late final AnimationController _animationController;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 70),
    );
    final curve = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.linear,
    );
    _opacity = curve;
    _scale = Tween<double>(begin: 0.98, end: 1).animate(curve);
  }

  @override
  void dispose() {
    _entry?.remove();
    _entry = null;
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PlayerPopupMenuButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final entry = _entry;
    if (entry == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _entry == entry) {
        entry.markNeedsBuild();
      }
    });
  }

  void _toggleMenu() {
    if (_entry == null) {
      _openMenu();
    } else {
      _closeMenu();
    }
  }

  void _openMenu() {
    widget.onVisibilityChanged?.call(true);
    final overlay = Overlay.of(context);
    _entry = OverlayEntry(
      builder: (overlayContext) => Stack(
        children: [
          Positioned.fill(
            child: Listener(
              key: const ValueKey('player-popup-menu-barrier'),
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => _closeMenu(),
            ),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.topCenter,
            followerAnchor: Alignment.bottomCenter,
            offset: const Offset(0, -PlayerPopupMenuMetrics.gapFromButton),
            child: Material(
              type: MaterialType.transparency,
              child: FadeTransition(
                key: const ValueKey('player-popup-menu-fade'),
                opacity: _opacity,
                child: ScaleTransition(
                  scale: _scale,
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(width: widget.menuWidth, child: widget.menuBuilder(overlayContext, _closeMenu)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_entry!);
    _animationController.forward(from: 0);
  }

  void _closeMenu() {
    final entry = _entry;
    if (entry == null || _isClosing) return;
    _isClosing = true;
    _animationController.reverse().whenComplete(() {
      if (!mounted || _entry != entry) return;
      entry.remove();
      _entry = null;
      _isClosing = false;
      widget.onVisibilityChanged?.call(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _toggleMenu, child: widget.child),
    );
  }
}

/// 倍速、音轨和字幕菜单共用的玻璃面板。
class PlayerPopupMenuPanel extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const PlayerPopupMenuPanel({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    const panelColor = Color(0xE817181A);
    final radius = BorderRadius.circular(PlayerPopupMenuMetrics.panelRadius);
    return DefaultTextStyle(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        decoration: TextDecoration.none,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 22, offset: Offset(0, 10))],
            ),
            child: ClipRRect(
              key: const ValueKey('player-popup-menu-panel'),
              borderRadius: radius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: panelColor,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xE61D1E21), Color(0xD917181A)],
                    ),
                    borderRadius: radius,
                    border: Border.all(color: Colors.white.withAlpha(28)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(height: 8),
                        ...children,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -1),
            child: CustomPaint(
              key: const ValueKey('player-popup-menu-pointer'),
              painter: const _MenuPointerPainter(panelColor),
              size: const Size(16, 9),
            ),
          ),
        ],
      ),
    );
  }
}

class PlayerPopupMenuItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  const PlayerPopupMenuItem({super.key, required this.label, required this.onPressed, this.selected = false});

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary(context);
    final foreground = selected ? Color.lerp(primary, Colors.white, 0.3)! : Colors.white;
    return AppClickableArea(
      onTap: onPressed,
      height: PlayerPopupMenuMetrics.itemHeight,
      borderRadius: BorderRadius.circular(AppRadii.control),
      backgroundColor: selected ? primary.withAlpha(52) : Colors.transparent,
      hoverColor: selected ? primary.withAlpha(18) : Colors.white.withAlpha(18),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          SizedBox(width: 20, child: selected ? Icon(Icons.check_rounded, color: foreground, size: 17) : null),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: foreground, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class PlayerPopupMenuDivider extends StatelessWidget {
  const PlayerPopupMenuDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Divider(height: 1, color: Colors.white.withAlpha(28)),
    );
  }
}

class PlayerPopupMenuSwitchItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const PlayerPopupMenuSwitchItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppClickableArea(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppRadii.control),
      hoverColor: Colors.white.withAlpha(14),
      padding: const EdgeInsets.fromLTRB(10, 6, 8, 2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withAlpha(128), fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          AppSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _MenuPointerPainter extends CustomPainter {
  final Color color;

  const _MenuPointerPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _MenuPointerPainter oldDelegate) => oldDelegate.color != color;
}
