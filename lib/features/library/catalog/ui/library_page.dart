// 【媒体库界面】展示电影、剧集及收藏目录，并管理网格滚动与分页。
// 通过媒体库 Provider 查询，界面不直接访问目录仓库。

import 'package:flutter/material.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/library/catalog/application/library_catalog_repository.dart';
import 'package:mochi_player/features/library/catalog/application/media_card_vo.dart';
import 'package:mochi_player/features/library/detail/ui/media_detail_page.dart';
import 'package:mochi_player/features/library/ui/widgets/library_item_poster_card.dart';
import 'package:mochi_player/features/library/ui/widgets/library_query_view.dart';
import 'package:mochi_player/features/library/ui/widgets/media_card.dart';
import 'package:mochi_player/features/library/ui/widgets/media_poster_grid.dart';
import 'package:mochi_player/l10n/l10n.dart';

enum LibraryCategory { movies, series, favorites }

class LibraryPage extends StatefulWidget {
  final LibraryCategory category;
  const LibraryPage({super.key, required this.category});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (widget.category) {
      LibraryCategory.movies => PagedLibraryQueryView<LibraryItem>(
        queryKey: widget.category,
        query: (r, limit) => r.watchTitles(kind: LibraryTitleKind.movie, limit: limit),
        builder: (context, items) => _buildMovieGrid(context, items),
      ),
      LibraryCategory.series => PagedLibraryQueryView<LibraryItem>(
        queryKey: widget.category,
        query: (r, limit) => r.watchTitles(kind: LibraryTitleKind.tvShow, limit: limit),
        builder: (context, items) => _buildTVShowGrid(context, items),
      ),
      LibraryCategory.favorites => PagedLibraryQueryView<MediaCardVO>(
        queryKey: widget.category,
        query: (r, limit) => r.watchFavorites(limit: limit),
        builder: (context, items) => _buildFavoritesGrid(context, items),
      ),
    };
  }

  Widget _buildMovieGrid(BuildContext context, List<LibraryItem> items) {
    if (items.isEmpty) {
      return _buildEmptyState(context.l10n.movies);
    }

    return _buildGridView(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return LibraryItemPosterCard(item: items[index]);
      },
    );
  }

  Widget _buildTVShowGrid(BuildContext context, List<LibraryItem> items) {
    if (items.isEmpty) {
      return _buildEmptyState(context.l10n.series);
    }

    return _buildGridView(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return LibraryItemPosterCard(item: items[index]);
      },
    );
  }

  Widget _buildFavoritesGrid(BuildContext context, List<MediaCardVO> items) {
    if (items.isEmpty) {
      return _buildEmptyState(context.l10n.favorites);
    }

    return _buildGridView(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        return MediaCard(
          title: item.title,
          subtitle: item.subtitle,
          imageUrl: item.imageUrl,
          rating: item.rating,
          artworkType: MediaArtworkType.poster,
          onTap: () {
            final libraryItem = item.libraryItem;
            if (libraryItem != null) {
              openMediaDetailPage(context, libraryItem);
            }
          },
        );
      },
    );
  }

  Widget _buildGridView({required int itemCount, required Widget Function(BuildContext, int) itemBuilder}) {
    return MediaPosterGrid<int>(
      items: List.generate(itemCount, (index) => index),
      itemBuilder: (context, index) => itemBuilder(context, index),
      storageKey: 'library-${widget.category.name}',
      controller: _scrollController,
    );
  }

  Widget _buildEmptyState(String category) {
    return AppResult(
      status: AppResultStatus.empty,
      title: context.l10n.noCategoryFound(category),
      subtitle: context.l10n.scanToDiscover,
    );
  }
}
