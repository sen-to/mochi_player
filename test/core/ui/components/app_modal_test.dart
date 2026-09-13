import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/ui/app_ui.dart';

void main() {
  testWidgets('shows the default footer and returns the confirmed result', (tester) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await AppModal.confirm(context: context, title: '清空媒体库？', message: '此操作不可撤销。');
              },
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    expect(find.text('取消'), findsOneWidget);
    expect(find.text('确定'), findsOneWidget);

    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('can omit the default footer', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                await AppModal.show(context: context, title: '处理中', content: const Text('请稍候'), showFooter: false);
              },
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    expect(find.text('处理中'), findsOneWidget);
    expect(find.text('请稍候'), findsOneWidget);
    expect(find.text('取消'), findsNothing);
    expect(find.text('确定'), findsNothing);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
  });
}
