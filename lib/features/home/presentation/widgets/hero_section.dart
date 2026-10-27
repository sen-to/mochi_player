import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/infrastructure/tmdb/tmdb_image_cache_manager.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/library/detail/media_detail_page.dart';
import 'package:mochi_player/features/library/widgets/media_rating_tag.dart';
import 'package:mochi_player/features/playback/presentation/playback_launcher.dart';
import 'package:mochi_player/l10n/l10n.dart';

/// 首页 Hero Section
/// 展示随机选择的一部电影或剧集，带有背景图、标题和操作按钮
class HeroSection extends StatelessWidget {
  final LibraryItem? heroItem;
  final VoidCallback? onRefresh;

  const HeroSection({super.key, required this.heroItem, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (heroItem == null) {
      return const SizedBox(height: 420);
    }

    final item = heroItem!;

    return SizedBox(
      height: 420,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 背景图
          _buildBackdropImage(item.backdropUrl, item.posterUrl),

          // 渐变遮罩
          _buildGradientOverlay(context),

          // 内容
          Positioned(
            bottom: 48,
            left: 40,
            right: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 评分 + 年份 + 类型
                _buildMetaRow(item.rating, item.releaseYear, item.genres),
                const SizedBox(height: 16),

                // 标题
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                    shadows: [Shadow(offset: Offset(0, 4), blurRadius: 20, color: Colors.black54)],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // 简介
                if (item.overview case final overview? when overview.isNotEmpty)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Text(
                      overview,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withAlpha(210),
                        height: 1.5,
                        shadows: const [Shadow(blurRadius: 10, color: Colors.black54)],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 24),

                // 操作按钮
                _buildActionButtons(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackdropImage(String? backdropUrl, String? posterUrl) {
    final imageUrl = backdropUrl ?? posterUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: const Color(0xFF1C1C1E),
        child: const Center(child: Icon(Icons.movie, color: Colors.white24, size: 120)),
      );
    }

    return CachedNetworkImage(
      cacheManager: TmdbImageCacheManager.instance,
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      placeholder: (context, url) => Container(color: const Color(0xFF1C1C1E)),
      errorWidget: (context, url, error) => Container(color: const Color(0xFF1C1C1E)),
    );
  }

  Widget _buildGradientOverlay(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = theme.scaffoldBackgroundColor;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withAlpha(44),
            Colors.black.withAlpha(140),
            bgColor.withAlpha(218),
            bgColor,
          ],
          stops: const [0.0, 0.32, 0.56, 0.86, 1.0],
        ),
      ),
    );
  }

  Widget _buildMetaRow(double rating, int? year, List<String> genres) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // 评分
        if (rating > 0) MediaRatingTag(rating: rating),

        // 年份
        if (year != null) AppTag(text: year.toString(), appearance: AppAppearance.overlay),

        // 类型标签
        ...genres.take(3).map((genre) => AppTag(text: genre, appearance: AppAppearance.overlay)),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        AppButton(
          onPressed: () => _handlePlay(context),
          icon: Icons.play_arrow_rounded,
          label: context.l10n.playback,
          size: AppButtonSize.regular,
        ),
        const SizedBox(width: 12),

        AppButton(
          onPressed: () => _handleMoreInfo(context),
          icon: Icons.info_outline_rounded,
          label: context.l10n.details,
          variant: AppButtonVariant.secondary,
          appearance: AppAppearance.overlay,
          size: AppButtonSize.regular,
        ),
      ],
    );
  }

  void _handlePlay(BuildContext context) {
    PlaybackLauncher.playLibraryItem(context, heroItem!);
  }

  void _handleMoreInfo(BuildContext context) {
    openMediaDetailPage(context, heroItem!);
  }
}
