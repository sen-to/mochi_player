// 【媒体库界面】展示海报、标题、评分及观看进度。
// 接收展示数据并使用共享图片缓存，不读取元数据表。

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:mochi_player/core/ui/images/media_network_image.dart';
import 'package:mochi_player/core/ui/theme/app_colors.dart';
import 'package:mochi_player/core/ui/theme/app_radii.dart';
import 'package:mochi_player/core/ui/theme/app_spacing.dart';
import 'package:mochi_player/l10n/l10n.dart';

enum MediaArtworkType { poster, backdrop }

/// 展示媒体图片及紧凑的媒体库信息。
class MediaCard extends StatefulWidget {
  const MediaCard({
    super.key,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.rating = 0,
    this.onTap,
    this.artworkType = MediaArtworkType.poster,
    this.progress,
  });

  final String title;
  final String? subtitle;
  final String? imageUrl;
  final double rating;
  final VoidCallback? onTap;
  final MediaArtworkType artworkType;
  final double? progress;

  @override
  State<MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<MediaCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = widget.onTap != null;
    final shadowColor = AppColors.cardShadow(context);

    return MouseRegion(
      onEnter: enabled ? (_) => setState(() => _isHovering = true) : null,
      onExit: enabled ? (_) => setState(() => _isHovering = false) : null,
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: enabled && _isHovering ? 1 : 0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuart,
          builder: (context, hoverProgress, child) {
            final titleColor = theme.textTheme.bodyMedium!.color!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    transform: Matrix4.identity()
                      ..scaleByDouble(1 + (0.025 * hoverProgress), 1 + (0.025 * hoverProgress), 1, 1),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadii.card),
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor.withAlpha((4 + (6 * hoverProgress)).round()),
                          blurRadius: 3 + (37 * hoverProgress),
                          offset: Offset(0, 1 + (19 * hoverProgress)),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.card),
                      child: Stack(
                        children: [
                          Positioned.fill(child: _buildImage(theme)),
                          if (widget.rating > 0)
                            Positioned(
                              top: AppSpacing.xs,
                              left: AppSpacing.xs,
                              child: _RatingBadge(rating: widget.rating),
                            ),
                          if (widget.progress != null)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: _PlaybackProgress(progress: widget.progress!),
                            ),
                          Positioned.fill(
                            child: Opacity(
                              opacity: 0.05 * hoverProgress,
                              child: ColoredBox(color: AppColors.mediaHoverOverlay(context)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.compact),
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color.lerp(titleColor, titleColor.withAlpha(204), hoverProgress),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Visibility.maintain(
                  visible: widget.subtitle != null,
                  child: Text(
                    widget.subtitle ?? '\u00A0',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium!.color!.withAlpha(153)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildImage(ThemeData theme) {
    final imageUrl = widget.imageUrl;
    if (imageUrl == null || imageUrl.isEmpty) return _buildPlaceholder();

    return MediaNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => ColoredBox(
        color: theme.canvasColor.withAlpha(128),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (context, url, error) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return ColoredBox(
      color: Colors.grey.shade800,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.artworkType == MediaArtworkType.backdrop ? Icons.videocam : Icons.movie,
            color: Colors.white54,
            size: 48,
          ),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(
              widget.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(179),
        borderRadius: BorderRadius.circular(AppRadii.small),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
          const SizedBox(width: 3),
          Text(
            NumberFormat('0.0', context.l10n.localeName).format(rating),
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _PlaybackProgress extends StatelessWidget {
  const _PlaybackProgress({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      color: Colors.black.withAlpha(115),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0, 1),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primary(context),
            borderRadius: const BorderRadius.only(topRight: Radius.circular(2), bottomRight: Radius.circular(2)),
          ),
        ),
      ),
    );
  }
}
