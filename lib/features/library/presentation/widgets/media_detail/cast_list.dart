import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/infrastructure/tmdb/tmdb_image_cache_manager.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/library/presentation/view_models/media_detail_view_model.dart';
import 'package:mochi_player/l10n/l10n.dart';

class CastList extends StatefulWidget {
  final MediaDetailViewModel viewModel;
  final double topPadding;

  const CastList({super.key, required this.viewModel, this.topPadding = 32});

  @override
  State<CastList> createState() => _CastListState();
}

class _CastListState extends State<CastList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.viewModel.cast.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: widget.topPadding),
        Text(
          context.l10n.cast,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: AppHorizontalScroller(
            controller: _scrollController,
            controlsBottomInset: 58,
            contentBuilder: (context, controller) => ListView.separated(
              controller: controller,
              scrollDirection: Axis.horizontal,
              itemCount: widget.viewModel.cast.length,
              separatorBuilder: (_, _) => const SizedBox(width: 20),
              itemBuilder: (context, index) => _buildCastItem(widget.viewModel.cast[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCastItem(Artist artist) {
    return Column(
      children: [
        ClipOval(
          child: SizedBox(
            width: 80,
            height: 80,
            child: artist.profileUrl != null
                ? CachedNetworkImage(
                    cacheManager: TmdbImageCacheManager.instance,
                    imageUrl: artist.profileUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _buildAvatarPlaceholder(),
                    errorWidget: (context, url, error) => _buildAvatarPlaceholder(),
                  )
                : _buildAvatarPlaceholder(),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 90,
          child: Text(
            artist.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.2),
          ),
        ),
        SizedBox(
          width: 90,
          child: Text(
            artist.character ?? "",
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: Colors.grey[600], height: 1.2),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.person, color: Colors.grey, size: 40),
    );
  }
}
