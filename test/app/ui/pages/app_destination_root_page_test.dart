// 【应用界面回归】验证媒体库入口共享全库搜索，退出后恢复原分类及滚动位置。
// 使用内存查询替身，避免数据库和图片请求干扰页面交互验证。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mochi_player/app/ui/navigation/app_destination.dart';
import 'package:mochi_player/app/ui/pages/app_destination_root_page.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/home/application/trending_media_provider.dart';
import 'package:mochi_player/features/home/application/trending_media_source.dart';
import 'package:mochi_player/features/library/application/media_library_provider.dart';
import 'package:mochi_player/features/library/catalog/application/library_catalog_repository.dart';
import 'package:mochi_player/features/library/catalog/domain/library_title_filter.dart';
import 'package:mochi_player/features/library/catalog/application/media_card_vo.dart';
import 'package:mochi_player/l10n/l10n.dart';
import 'package:provider/provider.dart';

void main() {
  for (final (dark, destination) in [
    (false, AppDestination.movies),
    (true, AppDestination.movies),
    (false, AppDestination.series),
    (true, AppDestination.series),
  ]) {
    testWidgets('${destination.name} 共用无水波纹工具栏，筛选即时应用（dark=$dark）', (tester) async {
      final category = destination == AppDestination.movies ? '电影' : '剧集';
      final filterTitle = find.text('筛选$category');
      const viewport = Size(560, 450);
      await tester.binding.setSurfaceSize(viewport);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final provider = _LibraryProvider();
      addTearDown(provider.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<MediaLibraryProvider>.value(
          value: provider,
          child: MaterialApp(
            theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Navigator(
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (_) => Scaffold(body: AppDestinationRootPage(destination: destination)),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('共 24 部$category'), findsOneWidget);
      final grid = tester.getTopLeft(find.byType(GridView));
      final filter = find.widgetWithText(AppClickableArea, '筛选');
      final sort = find.widgetWithText(AppClickableArea, '最近添加');
      final filterContext = tester.element(filter);
      expect(tester.widget<AppClickableArea>(filter).backgroundColor, AppColors.controlSurface(filterContext));
      final gridPadding = tester.widget<GridView>(find.byType(GridView)).padding! as EdgeInsets;
      expect(gridPadding.top, 108);
      expect(tester.getSize(sort).height, tester.getSize(filter).height);
      expect(tester.getRect(sort).left - tester.getRect(filter).right, AppSpacing.sm);
      final filterRect = tester.getRect(filter);
      expect(filterRect.height, lessThanOrEqualTo(28));
      await tester.tap(filter);
      await tester.pumpAndSettle();
      final dialog = find.ancestor(of: filterTitle, matching: find.byType(SingleChildScrollView)).first;
      final bounds = tester.getRect(dialog);
      expect(bounds.width, 360);
      expect(bounds.top, greaterThanOrEqualTo(filterRect.bottom));
      expect(bounds.left, greaterThanOrEqualTo(16));
      expect(bounds.right, lessThanOrEqualTo(viewport.width - 16));
      expect(bounds.bottom, lessThanOrEqualTo(viewport.height));
      expect(find.text('完成'), findsNothing);
      expect(find.text('已选择 0 项条件'), findsNothing);

      await tester.tap(find.byTooltip('更多类型'));
      await tester.pumpAndSettle();
      expect(find.text('恐怖'), findsOneWidget);
      await tester.tap(find.text('恐怖'));
      await tester.pumpAndSettle();
      expect(provider.catalogFilter.genres, {'恐怖'});
      await tester.tap(find.text('恐怖'));
      await tester.pumpAndSettle();
      expect(provider.catalogFilter.genres, isEmpty);
      await tester.tap(find.text('剧情'));
      await tester.pumpAndSettle();
      expect(provider.catalogFilter.genres, {'剧情'});
      expect(tester.widget<AppClickableArea>(filter).backgroundColor, AppColors.selectedSurface(filterContext));
      expect(tester.getRect(dialog).right, closeTo(bounds.right, 0.1));
      await tester.tap(find.text('全部年份'));
      await tester.pumpAndSettle();
      final yearLabel = find.text('2000 – 2009').last;
      final yearText = tester.widget<Text>(yearLabel);
      expect(yearText.maxLines, 1);
      final painter = TextPainter(
        text: TextSpan(text: yearText.data, style: yearText.style),
        textDirection: TextDirection.ltr,
      )..layout();
      expect(painter.width, lessThanOrEqualTo(tester.getSize(yearLabel).width));
      painter.dispose();
      await tester.tap(find.text('2000 – 2009').last);
      await tester.pumpAndSettle();
      expect(provider.catalogFilter.decade, 2000);
      expect(find.byKey(const ValueKey('catalog-filter-count')), findsNothing);
      expect(find.widgetWithText(AppClickableArea, '筛选'), findsOneWidget);
      expect(find.text('观看状态'), findsNothing);
      expect(tester.getTopLeft(find.byType(GridView)), grid);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(filterTitle, findsNothing);
      expect(provider.catalogFilter.count, 2);
      await tester.tap(filter);
      await tester.pumpAndSettle();
      await tester.tap(find.text('重置'));
      await tester.pumpAndSettle();
      expect(provider.catalogFilter.count, 0);
      expect(tester.widget<AppClickableArea>(filter).backgroundColor, AppColors.controlSurface(filterContext));
      expect(find.byKey(const ValueKey('catalog-filter-count')), findsNothing);
      await tester.tapAt(const Offset(10, 16));
      await tester.pumpAndSettle();
      expect(filterTitle, findsNothing);
      await tester.tap(find.text('最近添加'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('评分'));
      await tester.pumpAndSettle();
      expect(provider.catalogSort, LibraryTitleSort.rating);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('嵌套导航中展开筛选并切换类型', (tester) async {
    final provider = _LibraryProvider();
    addTearDown(provider.dispose);
    final router = GoRouter(
      initialLocation: '/movies',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => Scaffold(
            body: Row(
              children: [
                const SizedBox(width: 180),
                Expanded(child: shell),
              ],
            ),
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/movies',
                  builder: (context, state) => const AppDestinationRootPage(destination: AppDestination.movies),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/series',
                  builder: (context, state) => const AppDestinationRootPage(destination: AppDestination.series),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<MediaLibraryProvider>.value(
        value: provider,
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.darkTheme,
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('筛选'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('更多类型'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('恐怖'));
    await tester.pumpAndSettle();
    expect(provider.catalogFilter.genres, {'恐怖'});
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.tap(find.text('最近添加'));
    await tester.pumpAndSettle();
    expect(find.text('上映年份'), findsOneWidget);
    router.go('/series');
    await tester.pumpAndSettle();
    expect(find.text('上映年份'), findsNothing);
    router.go('/movies');
    await tester.pumpAndSettle();
    expect(find.text('上映年份'), findsNothing);
    await tester.tap(find.text('筛选'));
    await tester.pumpAndSettle();
    expect(find.text('筛选电影'), findsOneWidget);
    router.go('/series');
    await tester.pumpAndSettle();
    router.go('/movies');
    await tester.pumpAndSettle();
    expect(find.text('筛选电影'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('媒体库入口搜索全库，退出后保留原电影列表的滚动位置', (tester) async {
    final provider = _LibraryProvider();
    addTearDown(provider.dispose);
    final trending = TrendingMediaProvider(source: _UnconfiguredTrendingSource());
    addTearDown(trending.dispose);

    for (final destination in [
      AppDestination.home,
      AppDestination.movies,
      AppDestination.series,
      AppDestination.favorites,
    ]) {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MediaLibraryProvider>.value(value: provider),
            ChangeNotifierProvider<TrendingMediaProvider>.value(value: trending),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AppDestinationRootPage(key: ValueKey(destination), destination: destination),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('搜索媒体库…'), findsOneWidget);

      ScrollPosition? originalPosition;
      double? originalOffset;
      if (destination == AppDestination.movies) {
        await tester.drag(find.byType(GridView), const Offset(0, -450));
        await tester.pumpAndSettle();
        originalPosition = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
        originalOffset = originalPosition.pixels;
        expect(originalOffset, greaterThan(0));
      }

      await tester.enterText(find.byType(EditableText), '  跨分类  ');
      await tester.pumpAndSettle();
      expect(find.text('跨分类电影'), findsWidgets);
      expect(find.text('跨分类剧集'), findsWidgets);
      expect(find.text('电影 · 2020'), findsOneWidget);
      expect(find.text('剧集 · 2021'), findsOneWidget);

      if (destination == AppDestination.movies) {
        final input = find.byType(EditableText);
        final controller = tester.widget<EditableText>(input).controller;
        tester.testTextInput.updateEditingValue(
          const TextEditingValue(
            text: '跨分类',
            selection: TextSelection.collapsed(offset: 3),
            composing: TextRange(start: 0, end: 3),
          ),
        );
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(controller.text, '跨分类');
        expect(controller.value.composing, const TextRange(start: 0, end: 3));
        expect(tester.widget<EditableText>(input).focusNode.hasFocus, isTrue);

        Future<void> search(String query) async {
          await tester.enterText(input, query);
          await tester.pumpAndSettle();
        }

        ScrollPosition resultPosition() => tester
            .state<ScrollableState>(find.descendant(of: find.byType(GridView), matching: find.byType(Scrollable)))
            .position;

        Future<void> scrollResults() async {
          await tester.drag(find.byType(GridView), const Offset(0, -450));
          await tester.pumpAndSettle();
          expect(resultPosition().pixels, greaterThan(0));
        }

        await search('第一组');
        await scrollResults();
        final savedOffset = resultPosition().pixels;
        final navigator = tester.state<NavigatorState>(find.byType(Navigator));
        navigator.push<void>(MaterialPageRoute(builder: (_) => const Scaffold(body: Text('详情'))));
        await tester.pumpAndSettle();
        navigator.pop();
        await tester.pumpAndSettle();
        expect(resultPosition().pixels, savedOffset);

        await search('第二组');
        expect(resultPosition().pixels, 0);
        await scrollResults();
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        await search('第二组');
        expect(resultPosition().pixels, 0);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      } else {
        await tester.tap(find.byIcon(Icons.close));
      }
      await tester.pumpAndSettle();
      expect(find.text('跨分类电影'), findsNothing);
      expect(find.text('跨分类剧集'), findsNothing);
      if (originalPosition != null) {
        final restored = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
        expect(restored, same(originalPosition));
        expect(restored.pixels, originalOffset);
      }
    }

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _UnconfiguredTrendingSource extends Fake implements TrendingMediaSource {
  @override
  bool get isConfigured => false;
}

class _LibraryProvider extends ChangeNotifier implements MediaLibraryProvider {
  LibraryTitleFilter catalogFilter = const LibraryTitleFilter();
  LibraryTitleSort? catalogSort;

  @override
  bool get isLoading => false;

  @override
  bool get hasLibraryContent => false;

  @override
  Stream<List<LibraryItem>> watchTitles({
    LibraryTitleKind? kind,
    String query = '',
    bool recent = false,
    LibraryTitleFilter filter = const LibraryTitleFilter(),
    LibraryTitleSort? sort,
    int limit = 100,
  }) {
    if (sort != null) {
      catalogFilter = filter;
      catalogSort = sort;
    }
    if (query == '跨分类' && kind == null && !recent) {
      return Stream.value(const [
        Movie(tmdbId: 'movie', title: '跨分类电影', releaseYear: 2020),
        TVShow(tmdbId: 'series', title: '跨分类剧集', releaseYear: 2021),
      ]);
    }
    if (query == '第一组' || query == '第二组') {
      return Stream.value(List.generate(24, (index) => Movie(tmdbId: '$query-$index', title: '$query $index')));
    }
    return Stream.value(
      kind != null ? List.generate(24, (index) => Movie(tmdbId: '$index', title: '电影 $index')) : const [],
    );
  }

  @override
  Stream<LibraryTitleCatalogSummary> watchTitleCatalogSummary(LibraryTitleKind kind, LibraryTitleFilter filter) =>
      Stream.value((
        count: 24,
        genres: const ['剧情', '喜剧', '动作', '动画', '冒险', '历史', '家庭', '奇幻', '悬疑', '恐怖', '爱情', '科幻'],
        decades: const [2000],
      ));

  @override
  Stream<List<MediaCardVO>> watchFavorites({String query = '', int limit = 100}) => Stream.value(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
