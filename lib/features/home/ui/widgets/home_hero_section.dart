// 【首页推荐界面】展示横幅推荐、影片信息和播放／详情操作。
// 候选由媒体库入口提供；组件持有轮播计时器，悬停、聚焦和隐藏时暂停，销毁时取消。

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/core/ui/images/media_network_image.dart';
import 'package:mochi_player/features/library/detail/ui/media_detail_page.dart';
import 'package:mochi_player/features/library/ui/library_playback_launcher.dart';
import 'package:mochi_player/features/library/ui/widgets/media_rating_tag.dart';
import 'package:mochi_player/l10n/l10n.dart';

/// 首页推荐横幅；候选顺序由调用方确定，播放和详情始终作用于当前条目。
class HomeHeroSection extends StatefulWidget {
  const HomeHeroSection({super.key, required this.items});

  final List<LibraryItem> items;

  @override
  State<HomeHeroSection> createState() => _HomeHeroSectionState();
}

class _HomeHeroSectionState extends State<HomeHeroSection> {
  static const _rotationInterval = Duration(seconds: 20);
  Timer? _rotation;
  int _activeIndex = 0;
  bool _hovered = false;
  bool _focused = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleRotation();
  }

  @override
  void didUpdateWidget(HomeHeroSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 库刷新或候选重排时保留当前影片；影片被移除才回到首项。
    final previous = oldWidget.items.isEmpty ? null : oldWidget.items[_activeIndex];
    final nextIndex = previous == null
        ? -1
        : widget.items.indexWhere((item) => item.runtimeType == previous.runtimeType && item.tmdbId == previous.tmdbId);
    _activeIndex = nextIndex < 0 ? 0 : nextIndex;
    // 进度写入带来的同标题快照更新不重置轮播等待时间。
    if (nextIndex < 0 || oldWidget.items.length != widget.items.length) _scheduleRotation();
  }

  void _scheduleRotation() {
    _rotation?.cancel();
    _rotation = null;
    if (widget.items.length < 2 ||
        _hovered ||
        _focused ||
        !TickerMode.of(context) ||
        MediaQuery.disableAnimationsOf(context)) {
      return;
    }
    _rotation = Timer(_rotationInterval, () => _select((_activeIndex + 1) % widget.items.length));
  }

  void _select(int index) {
    if (_activeIndex != index) setState(() => _activeIndex = index);
    _scheduleRotation();
  }

  @override
  void dispose() {
    _rotation?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final duration = MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 450);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MouseRegion(
        onEnter: (_) {
          _hovered = true;
          _scheduleRotation();
        },
        onExit: (_) {
          _hovered = false;
          _scheduleRotation();
        },
        child: Focus(
          onFocusChange: (focused) {
            _focused = focused;
            _scheduleRotation();
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 700;
              final minHeight = (constraints.maxWidth / 4.2 + 20).clamp(260.0, 300.0).toDouble();
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRect(
                    child: AnimatedSwitcher(
                      duration: duration,
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      layoutBuilder: (current, previous) => Stack(
                        children: [
                          for (final child in previous)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: ExcludeFocus(child: ExcludeSemantics(child: child)),
                              ),
                            ),
                          ?current,
                        ],
                      ),
                      child: _HeroSlide(
                        key: ValueKey((widget.items[_activeIndex].runtimeType, widget.items[_activeIndex].tmdbId)),
                        item: widget.items[_activeIndex],
                        compact: compact,
                        width: constraints.maxWidth,
                        minHeight: minHeight,
                      ),
                    ),
                  ),
                  if (widget.items.length > 1)
                    SizedBox(
                      height: 20,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var index = 0; index < widget.items.length; index++)
                            Semantics(
                              selected: index == _activeIndex,
                              label: widget.items[index].title,
                              button: true,
                              child: AppClickableArea(
                                key: ValueKey('home-hero-indicator-$index'),
                                onTap: () => _select(index),
                                width: 24,
                                height: 20,
                                borderRadius: BorderRadius.circular(AppRadii.full),
                                hoverColor: AppColors.hoverSurface(context),
                                child: Center(
                                  child: AnimatedContainer(
                                    duration: duration,
                                    width: index == _activeIndex ? 18 : 6,
                                    height: index == _activeIndex ? 8 : 6,
                                    decoration: BoxDecoration(
                                      color: index == _activeIndex
                                          ? AppColors.primary(context).withAlpha(220)
                                          : AppColors.textSecondary(context),
                                      borderRadius: BorderRadius.circular(AppRadii.full),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HeroSlide extends StatelessWidget {
  const _HeroSlide({
    super.key,
    required this.item,
    required this.compact,
    required this.width,
    required this.minHeight,
  });

  static const _verticalInset = 24.0;
  static const _contentMaxWidth = 420.0;

  final LibraryItem item;
  final bool compact;
  final double width;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.scaffoldBackgroundColor;
    final isLight = theme.brightness == Brightness.light;
    final titleColor = isLight ? AppColors.textPrimary(context) : Colors.white;
    final overviewColor = isLight ? titleColor.withAlpha(220) : const Color(0xBFFFFFFF);
    final appearance = isLight ? AppAppearance.standard : AppAppearance.overlay;
    // 文字列末端的遮罩仍能衬托纯黑剧照上的简介，列外快速淡出。
    final contentEdge = math.min(_contentMaxWidth + AppSpacing.page, math.max(0.0, width - AppSpacing.page));
    final fadeEnd = contentEdge + 112;
    final clearSurface = surface.withAlpha(0);
    final overview = item.overview?.trim();
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Stack(
        children: [
          Positioned.fill(child: _backdrop(isLight ? surface : const Color(0xFF242426))),
          // 浅色从页面底色过渡到剧照，深色遮罩随高度向右展宽。
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: isLight
                    ? LinearGradient(
                        end: Alignment(2 * fadeEnd / math.max(1.0, width) - 1, 0),
                        colors: [surface.withAlpha(220), surface.withAlpha(155), surface.withAlpha(60), clearSurface],
                        stops: [0, contentEdge / fadeEnd, (contentEdge + 56) / fadeEnd, 1],
                      )
                    : LinearGradient(
                        colors: [
                          Colors.black.withAlpha(240),
                          Colors.black.withAlpha(215),
                          Colors.black.withAlpha(85),
                          Colors.transparent,
                          Colors.transparent,
                        ],
                        stops: const [0, 0.2, 0.43, 0.65, 1],
                        transform: const _HeroMaskTransform(),
                      ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isLight
                      ? [clearSurface, clearSurface, surface.withAlpha(35), surface.withAlpha(150), surface]
                      : [Colors.transparent, Colors.transparent, surface],
                  stops: isLight ? const [0, 0.72, 0.84, 0.94, 1] : const [0, 0.62, 1],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, _verticalInset, AppSpacing.page, _verticalInset),
            child: Align(
              alignment: Alignment.centerLeft,
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: _contentMaxWidth, minHeight: minHeight - 2 * _verticalInset),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'SourceHanSerif',
                            fontSize: compact ? 28 : 32,
                            fontWeight: FontWeight.w600,
                            color: titleColor,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (context, constraints) => Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (item.rating > 0) MediaRatingTag(rating: item.rating),
                              if (item.releaseYear != null) AppTag(text: '${item.releaseYear}', appearance: appearance),
                              ...item.genres
                                  .take(3)
                                  .map(
                                    (genre) => ConstrainedBox(
                                      constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: AppTag(text: genre, appearance: appearance),
                                      ),
                                    ),
                                  ),
                            ],
                          ),
                        ),
                        if (overview != null && overview.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            overview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14, color: overviewColor, height: 1.5),
                          ),
                        ],
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          AppButton(
                            onPressed: () => LibraryPlaybackLauncher.playLibraryItem(context, item),
                            icon: Icons.play_arrow_rounded,
                            label: context.l10n.playback,
                            size: AppButtonSize.regular,
                          ),
                          AppButton(
                            onPressed: () => openMediaDetailPage(context, item),
                            icon: Icons.info_outline_rounded,
                            label: context.l10n.details,
                            variant: AppButtonVariant.secondary,
                            appearance: appearance,
                            size: AppButtonSize.regular,
                          ),
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
    );
  }

  Widget _backdrop(Color fallbackColor) {
    final backdrop = item.backdropUrl?.trim();
    final poster = item.posterUrl?.trim();
    final url = backdrop != null && backdrop.isNotEmpty ? backdrop : poster;
    if (url == null || url.isEmpty) return ColoredBox(color: fallbackColor);
    return MediaNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      alignment: Alignment.topRight,
      placeholder: (_, _) => ColoredBox(color: fallbackColor),
      errorWidget: (_, _, _) => ColoredBox(color: fallbackColor),
    );
  }
}

// 将渐变随高度向右延展，形成上窄下宽的柔和遮罩。
class _HeroMaskTransform extends GradientTransform {
  const _HeroMaskTransform();

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) => Matrix4.identity()..setEntry(0, 1, 0.6);
}
