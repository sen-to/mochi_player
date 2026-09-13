import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/ui/app_ui.dart';

void main() {
  testWidgets('back variant owns the standard back affordance', (tester) async {
    var backCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: AppHeader.back(title: '媒体详情', onBack: () => backCount++),
        ),
      ),
    );

    expect(find.text('媒体详情'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    expect(backCount, 1);
  });

  testWidgets('regular header composes caller-owned trailing content', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: AppHeader(
            title: '文件浏览',
            trailing: SizedBox(key: ValueKey('header-trailing'), width: 300, child: AppSearchInput()),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('header-trailing')), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    expect(tester.getSize(find.byType(AppSearchInput)).width, 300);
  });
}
