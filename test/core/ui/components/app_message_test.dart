import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/ui/app_ui.dart';

void main() {
  testWidgets('stacks repeated messages and dismisses each independently', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const AppMessageHost(child: Scaffold()),
      ),
    );

    AppMessage.error('WebDAV 连接失败', duration: const Duration(seconds: 1));
    AppMessage.error('WebDAV 连接失败', duration: const Duration(seconds: 2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 140));

    expect(find.text('WebDAV 连接失败'), findsNWidgets(2));

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 140));
    expect(find.text('WebDAV 连接失败'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 140));
    expect(find.text('WebDAV 连接失败'), findsNothing);
  });

  testWidgets('keeps loading visible until its handle is dismissed', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const AppMessageHost(child: Scaffold()),
      ),
    );

    final loading = AppMessage.loading('正在获取播放链接…');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 140));
    expect(find.text('正在获取播放链接…'), findsOneWidget);

    loading.dismiss();
    await tester.pump(const Duration(milliseconds: 140));
    expect(find.text('正在获取播放链接…'), findsNothing);
  });

  testWidgets('slides the complete message into view without clipping it', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const AppMessageHost(child: Scaffold()),
      ),
    );

    AppMessage.error('整体下滑', duration: const Duration(seconds: 10));
    await tester.pump();
    await tester.pump();

    final item = find.byKey(const ValueKey(0));
    final transform = find.descendant(of: item, matching: find.byType(Transform));
    final initialHeight = tester.getSize(item).height;
    final initialOffset = tester.widget<Transform>(transform).transform.getTranslation().y;

    await tester.pump(const Duration(milliseconds: 70));
    final animatedHeight = tester.getSize(item).height;
    final animatedOffset = tester.widget<Transform>(transform).transform.getTranslation().y;

    await tester.pump(const Duration(milliseconds: 70));
    final settledHeight = tester.getSize(item).height;
    final settledOffset = tester.widget<Transform>(transform).transform.getTranslation().y;

    expect(animatedHeight, initialHeight);
    expect(settledHeight, initialHeight);
    expect(initialOffset, lessThan(animatedOffset));
    expect(animatedOffset, lessThan(settledOffset));
    expect(settledOffset, 0);
    expect(find.descendant(of: item, matching: find.byType(ClipRect)), findsNothing);
  });

  testWidgets('collapses a dismissed item while the queue closes its gap', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const AppMessageHost(child: Scaffold()),
      ),
    );

    final first = AppMessage.loading('第一条');
    AppMessage.error('第二条', duration: const Duration(seconds: 10));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 140));

    final initialTop = tester.getTopLeft(find.text('第二条')).dy;
    final initialHeight = tester.getSize(find.byKey(const ValueKey(0))).height;

    first.dismiss();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    final animatedTop = tester.getTopLeft(find.text('第二条')).dy;
    final animatedHeight = tester.getSize(find.byKey(const ValueKey(0))).height;

    await tester.pump(const Duration(milliseconds: 70));
    final settledTop = tester.getTopLeft(find.text('第二条')).dy;

    expect(animatedHeight, lessThan(initialHeight));
    expect(animatedTop, lessThan(initialTop));
    expect(settledTop, lessThan(animatedTop));
    expect(find.text('第一条'), findsNothing);
  });
}
