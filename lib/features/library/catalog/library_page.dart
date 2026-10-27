import 'package:flutter/material.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/library/catalog/media_card_view_data.dart';
import 'package:mochi_player/features/library/detail/media_detail_page.dart';
import 'package:mochi_player/features/library/widgets/library_item_poster_card.dart';
import 'package:mochi_player/features/library/widgets/library_query.dart';
import 'package:mochi_player/features/library/widgets/media_card.dart';
import 'package:mochi_player/features/library/widgets/media_poster_grid.dart';
import 'package:mochi_player/l10n/l10n.dart';

enum LibraryCategory { movies, series, favorites }

class LibraryPage extends StatefulWidget {
  final LibraryCategory category;
  final String searchQuery;

  const LibraryPage({super.key, required this.category, this.searchQuery = ''});

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
      LibraryCategory.movies => PagedLibraryQuery<LibraryItem>(
        queryKey: (widget.category, widget.searchQuery),
        query: (r, limit) => r.watchTitles(kind: 'movie', query: widget.searchQuery, limit: limit),
        builder: (context, items) => _buildMovieGrid(context, items),
      ),
      LibraryCategory.series => PagedLibraryQuery<LibraryItem>(
        queryKey: (widget.category, widget.searchQuery),
        query: (r, limit) => r.watchTitles(kind: 'show', query: widget.searchQuery, limit: limit),
        builder: (context, items) => _buildTVShowGrid(context, items),
      ),
      LibraryCategory.favorites => PagedLibraryQuery<MediaCardViewData>(
        queryKey: (widget.category, widget.searchQuery),
        query: (r, limit) => r.watchFavorites(query: widget.searchQuery, limit: limit),
        builder: (context, items) => _buildFavoritesGrid(context, items),
      ),
    };
  }

  Widget _buildMovieGrid(BuildContext context, List<LibraryItem> items) {
    if (items.isEmpty) {
      return _buildEmptyState(context.l10n.movies, hasQuery: _hasSearchQuery);
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
      return _buildEmptyState(context.l10n.series, hasQuery: _hasSearchQuery);
    }

    return _buildGridView(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return LibraryItemPosterCard(item: items[index]);
      },
    );
  }

  Widget _buildFavoritesGrid(BuildContext context, List<MediaCardViewData> items) {
    if (items.isEmpty) {
      return _buildEmptyState(context.l10n.favorites, hasQuery: _hasSearchQuery);
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

  bool get _hasSearchQuery => widget.searchQuery.trim().isNotEmpty;

  Widget _buildEmptyState(String category, {required bool hasQuery}) {
    return AppResult(
      status: AppResultStatus.empty,
      title: hasQuery ? context.l10n.noMatchingCategory(category) : context.l10n.noCategoryFound(category),
      subtitle: hasQuery ? context.l10n.tryOtherKeywords : context.l10n.scanToDiscover,
    );
  }
}
