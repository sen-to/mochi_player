// 【应用界面回归】验证媒体库入口共享全库搜索，退出后恢复原分类及滚动位置。
// 使用内存查询替身，避免数据库和图片请求干扰页面交互验证。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/app/ui/navigation/app_destination.dart';
import 'package:mochi_player/app/ui/pages/app_destination_root_page.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/home/application/trending_media_provider.dart';
import 'package:mochi_player/features/home/application/trending_media_source.dart';
import 'package:mochi_player/features/library/application/media_library_provider.dart';
import 'package:mochi_player/features/library/catalog/application/library_catalog_repository.dart';
import 'package:mochi_player/features/library/catalog/application/media_card_vo.dart';
import 'package:mochi_player/l10n/l10n.dart';
import 'package:provider/provider.dart';

void main() {
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
  @override
  bool get isLoading => false;

  @override
  bool get hasLibraryContent => false;

  @override
  Stream<List<LibraryItem>> watchTitles({
    LibraryTitleKind? kind,
    String query = '',
    bool recent = false,
    int limit = 100,
  }) {
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
      kind == LibraryTitleKind.movie
          ? List.generate(24, (index) => Movie(tmdbId: '$index', title: '电影 $index'))
          : const [],
    );
  }

  @override
  Stream<List<MediaCardVO>> watchFavorites({String query = '', int limit = 100}) => Stream.value(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
