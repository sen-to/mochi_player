// 【媒体库搜索】展示全库电影与剧集的搜索结果。
// 应用页面按搜索词挂载结果；本视图持有本轮滚动存储，查询订阅和分页由 PagedLibraryQueryView 管理。

import 'package:flutter/material.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/library/ui/widgets/library_item_poster_card.dart';
import 'package:mochi_player/features/library/ui/widgets/library_query_view.dart';
import 'package:mochi_player/features/library/ui/widgets/media_poster_grid.dart';
import 'package:mochi_player/l10n/l10n.dart';

class LibrarySearchResultsView extends StatefulWidget {
  const LibrarySearchResultsView({super.key, required this.query});

  final String query;

  @override
  State<LibrarySearchResultsView> createState() => _LibrarySearchResultsViewState();
}

class _LibrarySearchResultsViewState extends State<LibrarySearchResultsView> {
  final _scrollStorage = PageStorageBucket();

  @override
  Widget build(BuildContext context) {
    final query = widget.query;
    return PagedLibraryQueryView<LibraryItem>(
      queryKey: query,
      query: (provider, limit) => provider.watchTitles(query: query, limit: limit),
      builder: (context, items) {
        if (items.isEmpty) {
          return AppResult(
            status: AppResultStatus.empty,
            title: context.l10n.noMatchingMedia,
            subtitle: context.l10n.tryOtherKeywords,
          );
        }

        return PageStorage(
          bucket: _scrollStorage,
          child: MediaPosterGrid<LibraryItem>(
            items: items,
            itemBuilder: (context, item) => LibraryItemPosterCard(item: item, showMediaType: true),
            storageKey: 'library-search-results',
            topPadding: AppHeader.height + AppSpacing.xxl,
          ),
        );
      },
    );
  }
}
