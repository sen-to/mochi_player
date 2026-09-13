import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/ui/app_ui.dart';

void main() {
  testWidgets('renders configured status content and a custom icon', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const AppResult(
          status: AppResultStatus.empty,
          title: '没有匹配的媒体',
          subtitle: '请尝试其他关键词',
          icon: Icon(Icons.search_off_rounded),
        ),
      ),
    );

    expect(find.text('没有匹配的媒体'), findsOneWidget);
    expect(find.text('请尝试其他关键词'), findsOneWidget);
    expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
    final context = tester.element(find.byType(AppResult));
    final customIconTheme = IconTheme.of(tester.element(find.byIcon(Icons.search_off_rounded)));
    expect(customIconTheme.size, 32);
    expect(customIconTheme.color, AppColors.textSecondary(context));
    expect(_resultIconBackgrounds(tester), contains(AppColors.controlSurface(context)));
  });

  testWidgets('uses the status appearance and renders the operation area', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const AppResult(
          status: AppResultStatus.error,
          title: '页面加载失败',
          subtitle: '连接被拒绝',
          extra: TextButton(onPressed: null, child: Text('重试')),
        ),
      ),
    );

    expect(find.text('页面加载失败'), findsOneWidget);
    expect(find.text('连接被拒绝'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    final context = tester.element(find.byType(AppResult));
    expect(_resultIconBackgrounds(tester), contains(AppColors.controlSurface(context)));
  });

  testWidgets('uses the neutral background for an empty-state icon', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const AppResult(status: AppResultStatus.empty, title: '没有内容'),
      ),
    );

    final context = tester.element(find.byType(AppResult));
    expect(_resultIconBackgrounds(tester), contains(AppColors.controlSurface(context)));
  });

  testWidgets('uses the shared control background for an info-state icon', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const AppResult(status: AppResultStatus.info, title: '提示'),
      ),
    );

    final context = tester.element(find.byType(AppResult));
    expect(_resultIconBackgrounds(tester), contains(AppColors.controlSurface(context)));
  });
}

Iterable<Color?> _resultIconBackgrounds(WidgetTester tester) {
  return tester
      .widgetList<Container>(find.byType(Container))
      .map((container) => container.decoration)
      .whereType<BoxDecoration>()
      .map((decoration) => decoration.color);
}
