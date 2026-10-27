// 【行为测试】验证排列页面标题、操作区域及窗口控制区域。
// 测试对象的职责边界：窗口行为使用注入的窗口能力，不创建业务服务。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/l10n/l10n.dart';

void main() {
  testWidgets('back variant owns the standard back affordance', (tester) async {
    var backCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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
