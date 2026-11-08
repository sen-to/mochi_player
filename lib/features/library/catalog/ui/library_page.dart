// 【媒体库界面】展示侧边栏电影、剧集及收藏的根目录，并管理网格滚动与分页。
// 通过媒体库 Provider 查询，界面不直接访问目录仓库。

import 'package:flutter/material.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/library/application/media_library_provider.dart';
import 'package:mochi_player/features/library/catalog/application/library_catalog_repository.dart';
import 'package:mochi_player/features/library/catalog/application/media_card_vo.dart';
import 'package:mochi_player/features/library/catalog/domain/library_title_filter.dart';
import 'package:mochi_player/features/library/catalog/ui/library_catalog_toolbar.dart';
import 'package:mochi_player/features/library/detail/ui/media_detail_page.dart';
import 'package:mochi_player/features/library/ui/widgets/library_item_poster_card.dart';
import 'package:mochi_player/features/library/ui/widgets/library_query_view.dart';
import 'package:mochi_player/features/library/ui/widgets/media_card.dart';
import 'package:mochi_player/features/library/ui/widgets/media_poster_grid.dart';
import 'package:mochi_player/l10n/l10n.dart';
import 'package:provider/provider.dart';

enum LibraryCategory { movies, series, favorites }

class LibraryPage extends StatefulWidget {
  final LibraryCategory category;
  const LibraryPage({super.key, required this.category});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  static const _toolbarHeight = 40.0;

  late final ScrollController _scrollController;
  LibraryTitleFilter _filter = const LibraryTitleFilter();
  LibraryTitleSort _sort = LibraryTitleSort.latestAdded;
  Stream<LibraryTitleCatalogSummary>? _summary;

  LibraryTitleKind? get _kind => switch (widget.category) {
    LibraryCategory.movies => LibraryTitleKind.movie,
    LibraryCategory.series => LibraryTitleKind.tvShow,
    LibraryCategory.favorites => null,
  };

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _summary ??= _watchSummary();
  }

  @override
  void didUpdateWidget(LibraryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category == widget.category) return;
    _filter = const LibraryTitleFilter();
    _sort = LibraryTitleSort.latestAdded;
    _summary = _watchSummary();
  }

  Stream<LibraryTitleCatalogSummary>? _watchSummary() {
    final kind = _kind;
    return kind == null ? null : context.read<MediaLibraryProvider>().watchTitleCatalogSummary(kind, _filter);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kind = _kind;
    if (kind == null) {
      return PagedLibraryQueryView<MediaCardVO>(
        queryKey: widget.category,
        query: (r, limit) => r.watchFavorites(limit: limit),
        builder: (context, items) => _buildFavoritesGrid(context, items),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: PagedLibraryQueryView<LibraryItem>(
            queryKey: (kind, _filter, _sort),
            query: (r, limit) => r.watchTitles(kind: kind, filter: _filter, sort: _sort, limit: limit),
            builder: (context, items) {
              if (items.isEmpty) {
                if (_filter.count > 0) {
                  return AppResult(status: AppResultStatus.empty, title: context.l10n.catalogNoMatches);
                }
                return _buildEmptyState(kind == LibraryTitleKind.movie ? context.l10n.movies : context.l10n.series);
              }
              return _buildGridView(
                itemCount: items.length,
                itemBuilder: (context, index) => LibraryItemPosterCard(item: items[index]),
              );
            },
          ),
        ),
        Positioned(
          top: AppHeader.height,
          left: 0,
          right: 0,
          height: _toolbarHeight,
          child: StreamBuilder<LibraryTitleCatalogSummary>(
            stream: _summary,
            builder: (context, snapshot) => LibraryCatalogToolbar(
              kind: kind,
              summary: snapshot.data,
              filter: _filter,
              sort: _sort,
              onFilter: (filter) {
                if (_scrollController.hasClients) _scrollController.jumpTo(0);
                setState(() {
                  _filter = filter;
                  _summary = _watchSummary();
                });
              },
              onSort: (sort) {
                if (sort == _sort) return;
                if (_scrollController.hasClients) _scrollController.jumpTo(0);
                setState(() => _sort = sort);
              },
            ),
          ),
        ),
      ],
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
      topPadding: _kind == null ? 100 : AppHeader.height + _toolbarHeight + AppSpacing.sm,
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
