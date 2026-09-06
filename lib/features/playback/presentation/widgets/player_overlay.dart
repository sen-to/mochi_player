import 'package:flutter/material.dart';
import 'package:mochi_player/core/platform/window_controls_layout.dart';
import 'package:mochi_player/core/ui/app_ui.dart';

/// 播放器顶部信息栏和底部控制栏共用的布局规格。
class PlayerOverlayLayout {
  const PlayerOverlayLayout._();

  static const double topBarHeight = 60;
  static const double topButtonHeight = 36;
  static const double controlHeight = 34;
  static const Duration visibilityDuration = Duration(milliseconds: 200);

  static double bottomPanelWidth(double windowWidth) {
    if (windowWidth <= 700) {
      return (windowWidth - AppSpacing.lg * 2).clamp(0, double.infinity);
    }
    return (windowWidth * 0.58).clamp(560.0, 1040.0).toDouble();
  }

  /// 为左上角的系统窗口按钮预留空间。
  static double topLeftInset({required TargetPlatform platform, required bool isFullScreen}) {
    if (isFullScreen) return AppSpacing.xxl;
    return switch (platform) {
      TargetPlatform.macOS || TargetPlatform.windows => WindowControlsLayout.leadingContentInset,
      _ => AppSpacing.xxl,
    };
  }
}

/// Shared glass material for every floating control in the player.
abstract final class PlayerOverlayGlass {
  static const background = Color(0x52000000);
  static const border = Color(0x2EFFFFFF);
  static const blur = 18.0;
}

/// 根据当前播放器视口缩放 Mochi 字幕字号。
abstract final class PlayerSubtitleSizing {
  static const Size _referenceViewport = Size(1200, 700);

  static double fontSize({required double configuredFontSize, required Size viewportSize}) {
    final widthScale = viewportSize.width / _referenceViewport.width;
    final heightScale = viewportSize.height / _referenceViewport.height;
    final viewportScale = widthScale < heightScale ? widthScale : heightScale;
    final scale = viewportScale.clamp(0.3, 1.6);
    return (configuredFontSize * scale).clamp(10.0, 64.0).toDouble();
  }
}

/// 让字幕默认贴近窗口底部，仅在可见控制栏与字幕实际区域重叠时向上避让。
class PlayerSubtitleAvoidingControls extends StatelessWidget {
  final Widget child;
  final Rect? controlBarBounds;
  final bool controlsVisible;
  final bool isMiniPlayer;

  const PlayerSubtitleAvoidingControls({
    super.key,
    required this.child,
    required this.controlsVisible,
    required this.isMiniPlayer,
    this.controlBarBounds,
  });

  @override
  Widget build(BuildContext context) {
    return CustomSingleChildLayout(
      delegate: _SubtitleAvoidanceLayoutDelegate(
        controlBarBounds: controlBarBounds,
        shouldAvoidControls: controlsVisible && !isMiniPlayer,
      ),
      child: child,
    );
  }
}

class _SubtitleAvoidanceLayoutDelegate extends SingleChildLayoutDelegate {
  static const double _horizontalMargin = 20;
  static const double _bottomMargin = 20;
  static const double _controlGap = AppSpacing.xs;

  final Rect? controlBarBounds;
  final bool shouldAvoidControls;

  const _SubtitleAvoidanceLayoutDelegate({required this.controlBarBounds, required this.shouldAvoidControls});

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      maxWidth: (constraints.maxWidth - _horizontalMargin * 2).clamp(0, double.infinity),
      maxHeight: constraints.maxHeight,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final x = (size.width - childSize.width) / 2;
    final bottomPosition = size.height - _bottomMargin - childSize.height;
    var y = bottomPosition;
    final controls = controlBarBounds;

    if (shouldAvoidControls &&
        controls != null &&
        bottomPosition < controls.bottom + _controlGap &&
        bottomPosition + childSize.height > controls.top - _controlGap) {
      y = controls.top - _controlGap - childSize.height;
    }

    final preferredMinimumY = PlayerOverlayLayout.topBarHeight + AppSpacing.md;
    final minimumY = bottomPosition < preferredMinimumY ? bottomPosition : preferredMinimumY;
    return Offset(x, y.clamp(minimumY, bottomPosition).toDouble());
  }

  @override
  bool shouldRelayout(_SubtitleAvoidanceLayoutDelegate oldDelegate) {
    return controlBarBounds != oldDelegate.controlBarBounds || shouldAvoidControls != oldDelegate.shouldAvoidControls;
  }
}

/// 播放器顶部信息栏。
///
/// 只负责媒体标题和缓存速度，不持有播放状态。
class PlayerTopBar extends StatelessWidget {
  final String title;
  final String? secondaryTitle;
  final String cacheSpeed;
  final bool isFullScreen;

  const PlayerTopBar({
    super.key,
    required this.title,
    required this.cacheSpeed,
    required this.isFullScreen,
    this.secondaryTitle,
  });

  @override
  Widget build(BuildContext context) {
    final leftInset = PlayerOverlayLayout.topLeftInset(
      platform: Theme.of(context).platform,
      isFullScreen: isFullScreen,
    );

    return SizedBox(
      height: PlayerOverlayLayout.topBarHeight,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(left: leftInset, right: AppSpacing.xxl),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 9),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.2,
                            fontWeight: FontWeight.w600,
                            shadows: _topBarTextShadows,
                          ),
                        ),
                      ),
                      if (secondaryTitle case final value? when value.isNotEmpty) ...[
                        const SizedBox(width: AppSpacing.md),
                        Flexible(
                          child: Text(
                            value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.2,
                              fontWeight: FontWeight.w500,
                              shadows: _topBarTextShadows,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (cacheSpeed.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.xxl),
                Padding(
                  padding: const EdgeInsets.only(top: 9),
                  child: Text(
                    cacheSpeed,
                    key: const ValueKey('player-cache-speed'),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.2,
                      fontFeatures: [FontFeature.tabularFigures()],
                      shadows: _topBarTextShadows,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

const _topBarTextShadows = [Shadow(color: Color(0xB3000000), blurRadius: 8, offset: Offset(0, 1))];

/// 播放器底部玻璃控制面板。
///
/// 进度与具体按钮由上层注入，因此播放器状态和视觉容器保持解耦。
class PlayerBottomControlBar extends StatefulWidget {
  final Widget progress;
  final Widget controls;
  final ValueChanged<Rect>? onBoundsChanged;

  const PlayerBottomControlBar({super.key, required this.progress, required this.controls, this.onBoundsChanged});

  @override
  State<PlayerBottomControlBar> createState() => _PlayerBottomControlBarState();
}

class _PlayerBottomControlBarState extends State<PlayerBottomControlBar> {
  final GlobalKey _panelKey = GlobalKey();
  Offset _dragOffset = Offset.zero;
  Rect? _lastReportedBounds;

  Offset _clampOffset(Size windowSize, double panelWidth) {
    final horizontalRoom = ((windowSize.width - panelWidth) / 2 - AppSpacing.md).clamp(0.0, double.infinity);
    final upwardRoom = (windowSize.height - PlayerOverlayLayout.topBarHeight - 96).clamp(0.0, double.infinity);
    return Offset(_dragOffset.dx.clamp(-horizontalRoom, horizontalRoom), _dragOffset.dy.clamp(-upwardRoom, 0.0));
  }

  void _dragBy(DragUpdateDetails details, Size windowSize, double panelWidth) {
    setState(() {
      _dragOffset = _clampOffset(windowSize, panelWidth) + details.delta;
    });
  }

  void _reportBoundsAfterLayout() {
    if (widget.onBoundsChanged == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final renderBox = _panelKey.currentContext?.findRenderObject();
      if (renderBox is! RenderBox || !renderBox.hasSize) return;
      final bounds = renderBox.localToGlobal(Offset.zero) & renderBox.size;
      if (_lastReportedBounds == bounds) return;
      _lastReportedBounds = bounds;
      widget.onBoundsChanged?.call(bounds);
    });
  }

  @override
  Widget build(BuildContext context) {
    final windowSize = MediaQuery.sizeOf(context);
    final panelWidth = PlayerOverlayLayout.bottomPanelWidth(windowSize.width);
    final horizontalPadding = windowSize.width <= 1000 ? AppSpacing.md : AppSpacing.xl;
    final effectiveOffset = _clampOffset(windowSize, panelWidth);
    _reportBoundsAfterLayout();
    return SizedBox(
      width: windowSize.width,
      height: windowSize.height,
      child: SafeArea(
        top: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: (windowSize.width - panelWidth) / 2 + effectiveOffset.dx,
              bottom: AppSpacing.md - effectiveOffset.dy,
              width: panelWidth,
              child: SizedBox(
                key: _panelKey,
                child: AppGlassSurface(
                  key: const ValueKey('player-bottom-control-bar'),
                  borderRadius: const BorderRadius.all(Radius.circular(AppRadii.large)),
                  color: PlayerOverlayGlass.background,
                  borderColor: PlayerOverlayGlass.border,
                  blur: PlayerOverlayGlass.blur,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: MouseRegion(
                          cursor: SystemMouseCursors.move,
                          child: GestureDetector(
                            key: const ValueKey('player-control-bar-drag-surface'),
                            behavior: HitTestBehavior.opaque,
                            onPanUpdate: (details) => _dragBy(details, windowSize, panelWidth),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          AppSpacing.sm,
                          horizontalPadding,
                          AppSpacing.sm,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            widget.progress,
                            const SizedBox(height: AppSpacing.xs),
                            widget.controls,
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact controls used by the always-on-top mini-player window.
class PlayerMiniControls extends StatelessWidget {
  final bool isPlaying;
  final bool isAlwaysOnTop;
  final VoidCallback onPlayPause;
  final VoidCallback onToggleAlwaysOnTop;
  final VoidCallback onRestoreWindow;

  const PlayerMiniControls({
    super.key,
    required this.isPlaying,
    required this.isAlwaysOnTop,
    required this.onPlayPause,
    required this.onToggleAlwaysOnTop,
    required this.onRestoreWindow,
  });

  @override
  Widget build(BuildContext context) {
    return AppGlassSurface(
      key: const ValueKey('player-mini-controls'),
      borderRadius: const BorderRadius.all(Radius.circular(AppRadii.full)),
      color: PlayerOverlayGlass.background,
      borderColor: PlayerOverlayGlass.border,
      blur: PlayerOverlayGlass.blur,
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MiniPlayerControlButton(
            onPressed: onPlayPause,
            child: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 2),
          _MiniPlayerControlButton(
            onPressed: onToggleAlwaysOnTop,
            child: Icon(
              isAlwaysOnTop ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              color: isAlwaysOnTop ? Theme.of(context).colorScheme.primary : Colors.white70,
              size: 16,
            ),
          ),
          const SizedBox(width: 2),
          _MiniPlayerControlButton(
            onPressed: onRestoreWindow,
            child: const Icon(Icons.open_in_full_rounded, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }
}

class _MiniPlayerControlButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;

  const _MiniPlayerControlButton({required this.child, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AppClickableArea(
      width: 32,
      height: 32,
      onTap: onPressed,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadii.full)),
      hoverColor: const Color(0x18FFFFFF),
      child: Center(child: child),
    );
  }
}

/// 播放器控制按钮，只提供悬停反馈，不绘制 Material 水波纹或按压底色。
class PlayerControlButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final double width;
  final String? tooltip;

  const PlayerControlButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.width = PlayerOverlayLayout.controlHeight,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = AppClickableArea(
      width: width,
      height: PlayerOverlayLayout.controlHeight,
      onTap: onPressed,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadii.control)),
      hoverColor: const Color(0x1FFFFFFF),
      child: Center(child: child),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// 弹出菜单触发器使用的悬停表面。
///
/// 点击由外层菜单组件处理，这里只统一尺寸、圆角和悬停颜色。
class PlayerMenuButtonSurface extends StatefulWidget {
  final Widget child;
  final double width;

  const PlayerMenuButtonSurface({super.key, required this.child, this.width = PlayerOverlayLayout.controlHeight});

  @override
  State<PlayerMenuButtonSurface> createState() => _PlayerMenuButtonSurfaceState();
}

class _PlayerMenuButtonSurfaceState extends State<PlayerMenuButtonSurface> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    const hoverColor = Color(0x1FFFFFFF);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: _hovering ? 1 : 0),
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        builder: (context, progress, child) => Container(
          width: widget.width,
          height: PlayerOverlayLayout.controlHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Color.lerp(hoverColor.withAlpha(0), hoverColor, progress),
            borderRadius: const BorderRadius.all(Radius.circular(AppRadii.control)),
          ),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
