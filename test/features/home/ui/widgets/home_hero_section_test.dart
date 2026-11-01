// 【首页推荐回归】验证轮播切换、候选刷新、暂停及空数据和窄窗口布局。
// 使用本地业务对象，不请求图片或访问用户媒体库；卸载后检查计时器释放。

import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/home/ui/widgets/home_hero_section.dart';
import 'package:mochi_player/l10n/l10n.dart';

const _first = Movie(
  tmdbId: '1',
  title: '第一部电影',
  releaseYear: 2004,
  rating: 7.7,
  genres: ['剧情', '音乐'],
  overview: '一段用于展示影片故事的简介。',
);
const _second = Movie(tmdbId: '2', title: '第二部电影', releaseYear: 2002, overview: '另一段影片简介。');

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final titleFont = FontLoader('SourceHanSerif')
      ..addFont(rootBundle.load('assets/fonts/source_han_serif/SourceHanSerifSC-SemiBold.otf'));
    await titleFont.load();
  });

  Future<void> showHero(
    WidgetTester tester,
    List<LibraryItem> items, {
    double width = 1000,
    double textScale = 1,
    bool reducedMotion = false,
    bool enabled = true,
    bool lightTheme = false,
  }) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme ? AppTheme.lightTheme : AppTheme.darkTheme,
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale), disableAnimations: reducedMotion),
          child: Scaffold(
            body: TickerMode(
              enabled: enabled,
              child: HomeHeroSection(items: items),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('点击指示点切换，刷新候选时保留当前影片，移除后回到首项', (tester) async {
    await showHero(tester, [_first, _second]);
    expect(find.text(_first.title), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('home-hero-indicator-1')));
    await tester.pumpAndSettle();
    expect(find.text(_second.title), findsOneWidget);
    await showHero(tester, [_second, _first]);
    await tester.pumpAndSettle();
    expect(find.text(_second.title), findsOneWidget);
    await showHero(tester, [_first]);
    await tester.pumpAndSettle();
    expect(find.text(_first.title), findsOneWidget);
    expect(find.byKey(const ValueKey('home-hero-indicator-0')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('手动切换后重新等待二十秒，短内容保持紧凑高度', (tester) async {
    await showHero(tester, [_first, _second]);
    expect(tester.getSize(find.byType(HomeHeroSection)).height, 292);
    await tester.pump(const Duration(seconds: 19));
    await tester.tap(find.byKey(const ValueKey('home-hero-indicator-1')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(_second.title), findsOneWidget);
    await tester.pump(const Duration(seconds: 19));
    await tester.pumpAndSettle();
    expect(find.text(_first.title), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('同标题快照刷新不重置二十秒轮播', (tester) async {
    await showHero(tester, [_first, _second]);
    await tester.pump(const Duration(seconds: 19));
    await showHero(tester, [_first, _second]);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text(_second.title), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('二十秒自动切换，鼠标悬停暂停，离开后继续，卸载时释放计时器', (tester) async {
    await showHero(tester, [_first, _second]);
    await tester.pump(const Duration(seconds: 19));
    expect(find.text(_first.title), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text(_second.title), findsOneWidget);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.byType(HomeHeroSection)));
    await tester.pump();
    await tester.pump(const Duration(seconds: 40));
    expect(find.text(_second.title), findsOneWidget);
    await mouse.moveTo(const Offset(1, 850));
    await tester.pump();
    await tester.pump(const Duration(seconds: 20));
    await tester.pumpAndSettle();
    expect(find.text(_first.title), findsOneWidget);
    await mouse.removePointer();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 40));
    expect(tester.takeException(), isNull);
  });

  testWidgets('键盘聚焦横幅时暂停轮播，焦点移出后恢复', (tester) async {
    await showHero(tester, [_first, _second]);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.pump(const Duration(seconds: 40));
    expect(find.text(_first.title), findsOneWidget);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.pump(const Duration(seconds: 20));
    await tester.pumpAndSettle();
    expect(find.text(_second.title), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('减少动态效果或页面隐藏时暂停自动切换', (tester) async {
    await showHero(tester, [_first, _second], reducedMotion: true);
    await tester.pump(const Duration(seconds: 40));
    expect(find.text(_first.title), findsOneWidget);
    await showHero(tester, [_first, _second], enabled: false);
    await tester.pump(const Duration(seconds: 40));
    expect(find.text(_first.title), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('浅色与深色主题的未选中指示点使用主题文字色', (tester) async {
    for (final light in [true, false]) {
      await showHero(tester, [_first, _second], lightTheme: light);
      await tester.pumpAndSettle();
      final indicator = find.byKey(const ValueKey('home-hero-indicator-1'));
      final dot = tester.widget<AnimatedContainer>(
        find.descendant(of: indicator, matching: find.byType(AnimatedContainer)),
      );
      final context = tester.element(indicator);
      expect((dot.decoration! as BoxDecoration).color, AppColors.textSecondary(context));
      expect((dot.decoration! as BoxDecoration).color, isNot(Theme.of(context).scaffoldBackgroundColor));
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Tab 可到达指示点，Enter 与空格切换且聚焦时暂停轮播', (tester) async {
    await showHero(tester, [_first, _second]);
    final indicator = find.byKey(const ValueKey('home-hero-indicator-1'));
    bool indicatorFocused() =>
        Focus.of(tester.element(find.descendant(of: indicator, matching: find.byType(GestureDetector)))).hasFocus;
    for (var step = 0; step < 8 && !indicatorFocused(); step++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    expect(indicatorFocused(), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text(_second.title), findsOneWidget);
    await tester.pump(const Duration(seconds: 40));
    expect(find.text(_second.title), findsOneWidget);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(find.text(_first.title), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('空列表收起推荐，窄窗口和放大字号不溢出', (tester) async {
    await showHero(tester, []);
    expect(find.byType(AppButton), findsNothing);
    const longTitle = Movie(
      tmdbId: 'long',
      title: 'A very long movie title that should wrap without overflowing the hero banner',
      rating: 8,
      releaseYear: 2026,
      genres: ['Action & Adventure', 'Science Fiction', 'Television Movie'],
      overview: 'An overview that spans multiple lines while the title and controls remain visible.',
    );
    await showHero(tester, [longTitle]);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await showHero(tester, [longTitle], width: 380, textScale: 1.5);
    await tester.pumpAndSettle();
    expect(find.byType(AppButton), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
