import 'package:mochi_player/features/library/presentation/widgets/library_query.dart';
import 'package:flutter/material.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/home/application/trending_media_provider.dart';
import 'package:mochi_player/features/home/presentation/widgets/hero_section.dart';
import 'package:mochi_player/features/home/presentation/widgets/trending_category_card.dart';
import 'package:mochi_player/features/library/application/media_card_view_data.dart';
import 'package:mochi_player/features/library/application/media_library_provider.dart';
import 'package:mochi_player/features/library/presentation/pages/library_section_page.dart';
import 'package:mochi_player/features/library/presentation/widgets/continue_watching_card.dart';
import 'package:mochi_player/features/library/presentation/widgets/library_item_poster_card.dart';
import 'package:mochi_player/features/library/presentation/widgets/media_poster_grid.dart';
import 'package:provider/provider.dart';

class HomeContent extends StatefulWidget {
  final void Function(double offset)? onScroll;
  final String searchQuery;

  const HomeContent({super.key, this.onScroll, this.searchQuery = ''});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  late final ScrollController _mainScrollController;
  late final ScrollController _continueWatchingCtrl;
  late final ScrollController _recentlyAddedCtrl;

  @override
  void initState() {
    super.initState();
    _mainScrollController = ScrollController();
    _continueWatchingCtrl = ScrollController();
    _recentlyAddedCtrl = ScrollController();
    _mainScrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  void _onScroll() {
    if (!_mainScrollController.hasClients) return;
    widget.onScroll?.call(_mainScrollController.offset);
  }

  @override
  void dispose() {
    _mainScrollController.removeListener(_onScroll);
    _mainScrollController.dispose();
    _continueWatchingCtrl.dispose();
    _recentlyAddedCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.searchQuery.trim().isNotEmpty) {
      return _buildSearchResults(context);
    }

    final trendingState = context.select<TrendingMediaProvider, _TrendingShellState>(
      (provider) => _TrendingShellState(hasContent: provider.hasContent, isConfigured: provider.isConfigured),
    );
    return Selector<MediaLibraryProvider, _HomeShellState>(
      selector: (context, provider) => _HomeShellState(
        showInitialLoading: provider.isLoading && provider.totalFiles == 0,
        hasHomeContent: provider.hasLibraryContent || trendingState.hasContent || trendingState.isConfigured,
      ),
      builder: (context, shellState, child) {
        if (shellState.showInitialLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!shellState.hasHomeContent) {
          return const AppResult(status: AppResultStatus.empty, title: '媒体库为空', subtitle: '请先扫描媒体库以发现资源');
        }

        return CustomScrollView(
          key: const PageStorageKey('home-main-scroll'),
          controller: _mainScrollController,
          slivers: [
            // Hero Section (无 padding，直接到顶部)
            Selector<MediaLibraryProvider, LibraryItem?>(
              selector: (context, provider) => provider.heroItem,
              builder: (context, revision, child) {
                final heroItem = context.read<MediaLibraryProvider>().heroItem;
                return SliverToBoxAdapter(child: HeroSection(heroItem: heroItem));
              },
            ),

            // 继续观看
            Selector<MediaLibraryProvider, List<MediaCardViewData>>(
              selector: (context, provider) => provider.continueWatchingItems,
              builder: (context, revision, child) {
                final provider = context.read<MediaLibraryProvider>();
                final continueWatchingItems = provider.continueWatchingItems;
                if (continueWatchingItems.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }

                return SliverMainAxisGroup(
                  slivers: [
                    _buildSectionHeaderSliver(
                      context,
                      '继续观看',
                      onSeeAll: () => openLibrarySectionPage(context, LibrarySection.continueWatching),
                    ),
                    SliverToBoxAdapter(child: _buildContinueWatchingList(continueWatchingItems)),
                    const SliverToBoxAdapter(child: SizedBox(height: 30)),
                  ],
                );
              },
            ),

            // 最近添加
            Selector<MediaLibraryProvider, List<LibraryItem>>(
              selector: (context, provider) => provider.recentlyAddedContent,
              builder: (context, revision, child) {
                final recentlyAddedItems = context.read<MediaLibraryProvider>().recentlyAddedContent.take(15).toList();
                if (recentlyAddedItems.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }

                return SliverMainAxisGroup(
                  slivers: [
                    _buildSectionHeaderSliver(
                      context,
                      '最近添加',
                      onSeeAll: () => openLibrarySectionPage(context, LibrarySection.recentlyAdded),
                    ),
                    SliverToBoxAdapter(child: _buildRecentlyAddedList(recentlyAddedItems)),
                    const SliverToBoxAdapter(child: SizedBox(height: 30)),
                  ],
                );
              },
            ),

            // Trending on TMDB (三卡片布局)
            Consumer<TrendingMediaProvider>(
              builder: (context, provider, child) {
                if (!provider.hasContent && !provider.isConfigured) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }

                return SliverMainAxisGroup(
                  slivers: [
                    _buildSectionHeaderSliver(context, 'TMDB 趋势'),
                    SliverToBoxAdapter(child: _buildTrendingCards(provider)),
                    const SliverToBoxAdapter(child: SizedBox(height: 30)),
                  ],
                );
              },
            ),

            // 底部留白
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        );
      },
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    return PagedLibraryQuery<LibraryItem>(
      queryKey: widget.searchQuery,
      query: (repository, limit) => repository.watchTitles(query: widget.searchQuery, limit: limit),
      builder: (context, items) {
        if (items.isEmpty) {
          return const AppResult(status: AppResultStatus.empty, title: '没有匹配的媒体', subtitle: '请尝试其他关键词');
        }

        return MediaPosterGrid<LibraryItem>(
          items: items,
          itemBuilder: (context, item) => LibraryItemPosterCard(item: item),
          storageKey: 'home-search-results',
          topPadding: AppHeader.height + AppSpacing.xxl,
        );
      },
    );
  }

  SliverToBoxAdapter _buildSectionHeaderSliver(BuildContext context, String title, {VoidCallback? onSeeAll}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, 15),
        child: Row(
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Spacer(),
            if (onSeeAll != null)
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onSeeAll,
                  child: Row(
                    children: [
                      Text(
                        '查看全部',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[500]),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueWatchingList(List<MediaCardViewData> items) {
    const double wideImageWidth = 280;
    const double wideImageHeight = 158;
    const double textSectionHeight = 48;
    final double listHeight = wideImageHeight + textSectionHeight;

    return SizedBox(
      height: listHeight,
      child: AppHorizontalScroller(
        controller: _continueWatchingCtrl,
        controlsBottomInset: textSectionHeight,
        contentBuilder: (context, controller) => ListView.builder(
          key: const PageStorageKey('home-continue-watching-scroll'),
          controller: controller,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          itemBuilder: (context, index) {
            return SizedBox(
              width: wideImageWidth,
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xl),
                child: ContinueWatchingCard(item: items[index]),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecentlyAddedList(List<LibraryItem> items) {
    const double posterWidth = 160;
    const double posterHeight = 200;
    const double textSectionHeight = 48;
    final double listHeight = posterHeight + textSectionHeight;

    return SizedBox(
      height: listHeight,
      child: AppHorizontalScroller(
        controller: _recentlyAddedCtrl,
        controlsBottomInset: textSectionHeight,
        contentBuilder: (context, controller) => ListView.builder(
          key: const PageStorageKey('home-recently-added-scroll'),
          controller: controller,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          itemBuilder: (context, index) {
            return SizedBox(
              width: posterWidth,
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xl),
                child: LibraryItemPosterCard(item: items[index]),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 构建趋势三卡片布局
  Widget _buildTrendingCards(TrendingMediaProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trending Movies
          Expanded(
            child: TrendingCategoryCard(
              config: const TrendingCardConfig(
                icon: Icons.local_fire_department_rounded,
                iconColor: Color(0xFFFF6B35),
                title: '热门电影',
                subtitle: '全球前三',
              ),
              items: provider.movies,
              isLoading: provider.isLoading || !provider.hasContent,
            ),
          ),
          const SizedBox(width: 16),
          // Trending TV
          Expanded(
            child: TrendingCategoryCard(
              config: TrendingCardConfig(
                icon: Icons.tv_rounded,
                iconColor: AppColors.primary(context),
                title: '热门剧集',
                subtitle: '最多观看',
              ),
              items: provider.tvShows,
              isLoading: provider.isLoading || !provider.hasContent,
            ),
          ),
          const SizedBox(width: 16),
          // Top Rated
          Expanded(
            child: TrendingCategoryCard(
              config: const TrendingCardConfig(
                icon: Icons.star_rounded,
                iconColor: Color(0xFFFFD60A),
                title: '高分佳作',
                subtitle: '评分最高',
              ),
              items: provider.topRated,
              isLoading: provider.isLoading || !provider.hasContent,
              showRating: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeShellState {
  final bool showInitialLoading;
  final bool hasHomeContent;

  const _HomeShellState({required this.showInitialLoading, required this.hasHomeContent});

  @override
  bool operator ==(Object other) {
    return other is _HomeShellState &&
        other.showInitialLoading == showInitialLoading &&
        other.hasHomeContent == hasHomeContent;
  }

  @override
  int get hashCode => Object.hash(showInitialLoading, hasHomeContent);
}

class _TrendingShellState {
  const _TrendingShellState({required this.hasContent, required this.isConfigured});

  final bool hasContent;
  final bool isConfigured;

  @override
  bool operator ==(Object other) =>
      other is _TrendingShellState && other.hasContent == hasContent && other.isConfigured == isConfigured;

  @override
  int get hashCode => Object.hash(hasContent, isConfigured);
}
