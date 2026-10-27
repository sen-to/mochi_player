// 【行为测试】验证展示侧栏目的地、当前选择与设置入口。
// 测试对象的职责边界：导航动作由调用方回调处理。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/app/ui/navigation/app_destination.dart';
import 'package:mochi_player/app/ui/widgets/app_sidebar.dart';
import 'package:mochi_player/core/ui/theme/app_theme.dart';
import 'package:mochi_player/l10n/l10n.dart';

void main() {
  testWidgets('selects destinations by identity instead of numeric indexes', (tester) async {
    var selectedDestination = AppDestination.home;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.lightTheme,
        home: StatefulBuilder(
          builder: (context, setState) => AppSidebar(
            selectedDestination: selectedDestination,
            onDestinationSelected: (destination) {
              setState(() => selectedDestination = destination);
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('电影'));
    await tester.pump();

    expect(selectedDestination, AppDestination.movies);
  });
}
