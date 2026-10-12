import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:mochi_player/core/domain/media/trending_item.dart';
import 'package:mochi_player/core/infrastructure/tmdb/tmdb_image_cache_manager.dart';
import 'package:mochi_player/core/ui/theme/app_colors.dart';
import 'package:mochi_player/l10n/l10n.dart';

/// 趋势分类卡片配置
class TrendingCardConfig {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const TrendingCardConfig({required this.icon, required this.iconColor, required this.title, required this.subtitle});
}

/// 趋势分类卡片
/// 用于首页显示 Trending Movies / Trending TV / Top Rated
class TrendingCategoryCard extends StatelessWidget {
  final TrendingCardConfig config;
  final List<TrendingItem> items;
  final bool isLoading;
  final bool showRating;
  final VoidCallback? onTap;

  const TrendingCategoryCard({
    super.key,
    required this.config,
    required this.items,
    this.isLoading = false,
    this.showRating = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.canvasColor.withAlpha(128),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withAlpha(40), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(theme),
          const SizedBox(height: 16),
          if (isLoading)
            _buildLoadingState(theme)
          else if (items.isEmpty)
            _buildEmptyState(context, theme)
          else
            ...items.asMap().entries.map(
              (entry) => _TrendingListItem(
                item: entry.value,
                rank: entry.key + 1,
                showRating: showRating,
                isLast: entry.key == items.length - 1,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: config.iconColor.withAlpha(30), borderRadius: BorderRadius.circular(8)),
              child: Icon(config.icon, color: config.iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    config.subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: theme.textTheme.bodySmall?.color?.withAlpha(128),
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, color: theme.textTheme.bodySmall?.color?.withAlpha(128), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    final skeletonColor = theme.dividerColor.withAlpha(52);
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index == 2 ? 0 : 12),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 20,
                decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(5)),
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 60,
                decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(6)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: index == 1 ? 92 : 128,
                      decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(5)),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 11,
                      width: 72,
                      decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(5)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Text(
          context.l10n.noData,
          style: TextStyle(color: theme.textTheme.bodySmall?.color?.withAlpha(128), fontSize: 13),
        ),
      ),
    );
  }
}

/// 列表项组件
class _TrendingListItem extends StatefulWidget {
  final TrendingItem item;
  final int rank;
  final bool showRating;
  final bool isLast;

  const _TrendingListItem({required this.item, required this.rank, required this.showRating, required this.isLast});

  @override
  State<_TrendingListItem> createState() => _TrendingListItemState();
}

class _TrendingListItemState extends State<_TrendingListItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hoverBgColor = AppColors.hoverSurface(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: Padding(
        padding: EdgeInsets.only(bottom: widget.isLast ? 0 : 4),
        child: Stack(
          children: [
            // 悬停背景
            Positioned.fill(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isHovering ? 1.0 : 0.0,
                child: Container(
                  decoration: BoxDecoration(color: hoverBgColor, borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            // 内容
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  // 排名
                  SizedBox(
                    width: 24,
                    child: Text(
                      widget.rank.toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: theme.textTheme.bodyLarge?.color?.withAlpha(120),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 海报
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(width: 40, height: 60, child: _buildPoster()),
                  ),
                  const SizedBox(width: 12),
                  // 信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        _buildSubtitleRow(theme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoster() {
    if (widget.item.posterUrl != null) {
      return CachedNetworkImage(
        cacheManager: TmdbImageCacheManager.instance,
        imageUrl: widget.item.posterUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: Colors.grey[800]),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[800],
          child: const Icon(Icons.movie, color: Colors.white38, size: 20),
        ),
      );
    }
    return Container(
      color: Colors.grey[800],
      child: const Icon(Icons.movie, color: Colors.white38, size: 20),
    );
  }

  Widget _buildSubtitleRow(ThemeData theme) {
    if (widget.showRating) {
      return Row(
        children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
          const SizedBox(width: 4),
          Text(
            NumberFormat('0.0', context.l10n.localeName).format(widget.item.rating),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.amber[300]),
          ),
        ],
      );
    }

    final parts = <String>[];
    if (widget.item.genres.isNotEmpty) {
      parts.add(widget.item.genres.first);
    }
    if (widget.item.releaseYear != null) {
      parts.add(widget.item.releaseYear.toString());
    }

    return Text(
      parts.join(' • '),
      style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color?.withAlpha(153)),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
