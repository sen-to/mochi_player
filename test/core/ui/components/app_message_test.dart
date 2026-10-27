// 【行为测试】验证提供成功、失败、警告和加载提示及其队列宿主。
// 测试对象的职责边界：消息归属调用方所在视图；加载提示由返回的句柄关闭。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/l10n/l10n.dart';

void main() {
  testWidgets('messages stay with their view and closing a player host preserves the library host', (tester) async {
    Widget page({required bool playerOpen}) => MaterialApp(
      theme: AppTheme.darkTheme,
      home: Row(
        children: [
          const Expanded(
            child: AppMessageHost(
              key: ValueKey('library-host'),
              child: SizedBox(key: ValueKey('library')),
            ),
          ),
          if (playerOpen)
            const Expanded(
              child: AppMessageHost(
                key: ValueKey('player-host'),
                child: SizedBox(key: ValueKey('player')),
              ),
            ),
        ],
      ),
    );
    await tester.pumpWidget(page(playerOpen: true));
    AppMessage.error(tester.element(find.byKey(const ValueKey('library'))), 'Library notice');
    AppMessage.error(tester.element(find.byKey(const ValueKey('player'))), 'Subtitle error');
    await tester.pump();
    expect(
      find.descendant(of: find.byKey(const ValueKey('library-host')), matching: find.text('Library notice')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byKey(const ValueKey('library-host')), matching: find.text('Subtitle error')),
      findsNothing,
    );
    expect(
      find.descendant(of: find.byKey(const ValueKey('player-host')), matching: find.text('Subtitle error')),
      findsOneWidget,
    );
    await tester.pumpWidget(page(playerOpen: false));
    AppMessage.success(tester.element(find.byKey(const ValueKey('library'))), 'Library still works');
    await tester.pump();
    expect(find.text('Library still works'), findsOneWidget);
    expect(find.text('Subtitle error'), findsNothing);
  });
  testWidgets('stacks repeated messages and dismisses each independently', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.darkTheme,
        home: const AppMessageHost(child: Scaffold()),
      ),
    );

    AppMessage.error(tester.element(find.byType(Scaffold)), 'WebDAV 连接失败', duration: const Duration(seconds: 1));
    AppMessage.error(tester.element(find.byType(Scaffold)), 'WebDAV 连接失败', duration: const Duration(seconds: 2));
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
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.darkTheme,
        home: const AppMessageHost(child: Scaffold()),
      ),
    );

    final loading = AppMessage.loading(tester.element(find.byType(Scaffold)), '正在获取播放链接…');
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
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.darkTheme,
        home: const AppMessageHost(child: Scaffold()),
      ),
    );

    AppMessage.error(tester.element(find.byType(Scaffold)), '整体下滑', duration: const Duration(seconds: 10));
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
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.darkTheme,
        home: const AppMessageHost(child: Scaffold()),
      ),
    );

    final first = AppMessage.loading(tester.element(find.byType(Scaffold)), '第一条');
    AppMessage.error(tester.element(find.byType(Scaffold)), '第二条', duration: const Duration(seconds: 10));
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
