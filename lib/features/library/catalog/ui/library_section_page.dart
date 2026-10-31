// 【媒体库界面】展示收藏、续播或最近添加等完整分区。
// 查询状态由通用查询组件与 Provider 协作管理。

import 'package:mochi_player/features/library/catalog/application/library_catalog_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mochi_player/app/routing/app_route_paths.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/library/catalog/application/media_card_vo.dart';
import 'package:mochi_player/features/library/ui/widgets/continue_watching_card.dart';
import 'package:mochi_player/features/library/ui/widgets/library_item_poster_card.dart';
import 'package:mochi_player/features/library/ui/widgets/library_query_view.dart';
import 'package:mochi_player/l10n/l10n.dart';

/// Section 类型
enum LibrarySection { continueWatching, movies, tvShows, recentlyAdded }

void openLibrarySectionPage(BuildContext context, LibrarySection section) {
  context.push(AppRoutePaths.librarySection(section.name));
}

class LibrarySectionPage extends StatefulWidget {
  final LibrarySection section;

  const LibrarySectionPage({super.key, required this.section});

  @override
  State<LibrarySectionPage> createState() => _LibrarySectionPageState();
}

class _LibrarySectionPageState extends State<LibrarySectionPage> {
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: _SectionPageContent(section: widget.section, scrollController: _scrollController),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: AppHeader.height,
            child: AppHeader.back(title: _sectionTitle(context, widget.section)),
          ),
        ],
      ),
    );
  }
}

class _SectionPageContent extends StatelessWidget {
  final LibrarySection section;
  final ScrollController scrollController;

  const _SectionPageContent({required this.section, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return switch (section) {
      LibrarySection.continueWatching => PagedLibraryQueryView<MediaCardVO>(
        queryKey: section,
        query: (r, limit) => r.watchContinueWatching(limit: limit),
        builder: (context, items) => _buildSection(context, items, (item) => ContinueWatchingCard(item: item)),
      ),
      LibrarySection.movies => _titles(LibraryTitleKind.movie),
      LibrarySection.tvShows => _titles(LibraryTitleKind.tvShow),
      LibrarySection.recentlyAdded => _titles(null),
    };
  }

  Widget _titles(LibraryTitleKind? kind) => PagedLibraryQueryView<LibraryItem>(
    queryKey: section,
    query: (r, limit) => r.watchTitles(kind: kind, recent: section == LibrarySection.recentlyAdded, limit: limit),
    builder: (context, items) => _buildSection(context, items, (item) => LibraryItemPosterCard(item: item)),
  );

  Widget _buildSection<T>(BuildContext context, List<T> items, Widget Function(T item) itemBuilder) {
    if (items.isEmpty) {
      final title = _sectionTitle(context, section);
      return AppResult(
        status: AppResultStatus.empty,
        title: context.l10n.categoryEmpty(title),
        subtitle: context.l10n.scanToDiscover,
      );
    }

    return _buildGrid(items, itemBuilder);
  }

  Widget _buildGrid<T>(List<T> items, Widget Function(T item) itemBuilder) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isBackdrop = section == LibrarySection.continueWatching;
        final contentWidth = constraints.maxWidth - 80;
        final crossAxisCount = isBackdrop
            ? (contentWidth / 280).floor().clamp(2, 8).toInt()
            : _libraryPosterColumnCount(contentWidth);

        return GridView.builder(
          key: PageStorageKey<String>('library-section-${section.name}'),
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(40, AppHeader.height + 40, 40, isBackdrop ? 44 : 40),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: isBackdrop ? 1.35 : 0.57,
            crossAxisSpacing: isBackdrop ? 20 : 24,
            mainAxisSpacing: isBackdrop ? 24 : 32,
          ),
          itemBuilder: (context, index) {
            return itemBuilder(items[index]);
          },
        );
      },
    );
  }

  int _libraryPosterColumnCount(double contentWidth) {
    const desiredItemWidth = 180.0;
    final crossAxisCount = (contentWidth / desiredItemWidth).round();
    return crossAxisCount < 3 ? 3 : crossAxisCount;
  }
}

String _sectionTitle(BuildContext context, LibrarySection section) {
  switch (section) {
    case LibrarySection.continueWatching:
      return context.l10n.continueWatching;
    case LibrarySection.recentlyAdded:
      return context.l10n.recentlyAdded;
    case LibrarySection.movies:
      return context.l10n.movies;
    case LibrarySection.tvShows:
      return context.l10n.series;
  }
}
