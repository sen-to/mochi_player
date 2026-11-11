// 【行为测试】验证应用浮层的视觉规格由 AppMenuSurface 统一提供。
// 筛选面板与下拉菜单必须共用同一阴影与悬浮层次，避免各入口再次分叉。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/library/catalog/application/library_catalog_repository.dart';
import 'package:mochi_player/features/library/catalog/domain/library_title_filter.dart';
import 'package:mochi_player/features/library/catalog/ui/library_catalog_toolbar.dart';
import 'package:mochi_player/l10n/l10n.dart';

Widget _host({required Widget child, ThemeData? theme}) {
  return MaterialApp(
    locale: const Locale('zh'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: theme ?? AppTheme.lightTheme,
    home: Scaffold(body: child),
  );
}

/// 收集浮层根 Material 的阴影颜色；菜单与筛选面板都由 MenuAnchor 生成。
Set<Color?> _surfaceShadowColors(WidgetTester tester) {
  return tester
      .widgetList<Material>(find.byType(Material))
      .where((material) => material.elevation == AppMenuSurface.elevation)
      .map((material) => material.shadowColor)
      .toSet();
}

/// 收集浮层根 Material 的圆角；圆角必须与菜单一致。
Set<double> _surfaceRadii(WidgetTester tester) {
  return tester
      .widgetList<Material>(find.byType(Material))
      .where((material) => material.elevation == AppMenuSurface.elevation)
      .map((material) => (material.shape! as RoundedRectangleBorder).borderRadius.resolve(TextDirection.ltr).topLeft.x)
      .toSet();
}

void main() {
  testWidgets('筛选面板与下拉菜单使用同一套浮层阴影', (tester) async {
    await tester.pumpWidget(
      _host(
        child: Center(
          child: AppDropdown<String>(
            onSelected: (_) {},
            options: const [AppDropdownOption(value: 'a', label: '选项')],
            trigger: const SizedBox(width: 60, height: 30, child: Text('菜单')),
          ),
        ),
      ),
    );
    await tester.tap(find.text('菜单'));
    await tester.pumpAndSettle();
    final dropdownShadows = _surfaceShadowColors(tester);
    final dropdownRadii = _surfaceRadii(tester);
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      _host(
        child: LibraryCatalogToolbar(
          kind: LibraryTitleKind.movie,
          summary: null,
          filter: const LibraryTitleFilter(),
          sort: LibraryTitleSort.latestAdded,
          onFilter: (_) {},
          onSort: (_) {},
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    final filterShadows = _surfaceShadowColors(tester);
    final filterRadii = _surfaceRadii(tester);
    final triggerRadii = tester
        .widgetList<AppClickableArea>(
          find.descendant(of: find.byType(LibraryCatalogToolbar), matching: find.byType(AppClickableArea)),
        )
        .map((area) => area.borderRadius)
        .toSet();

    expect(dropdownShadows, isNotEmpty);
    expect(filterShadows, isNotEmpty);
    expect(filterShadows, dropdownShadows);
    expect(dropdownShadows, {AppMenuSurface.shadowColor(tester.element(find.byType(Scaffold).last))});
    expect(filterRadii, dropdownRadii);
    expect(dropdownRadii, {AppRadii.control});
    // 下拉触发控件与弹出面板必须同圆角，避免触发框比菜单更方或更圆。
    expect(triggerRadii, isNotEmpty);
    expect(triggerRadii, {AppDropdown.triggerRadius});
    expect(AppDropdown.triggerRadius, AppMenuSurface.radius);
  });

  testWidgets('浅色主题使用轻阴影', (tester) async {
    late Color shadow;
    await tester.pumpWidget(
      _host(
        child: Builder(
          builder: (context) {
            shadow = AppMenuSurface.shadowColor(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(shadow.a, closeTo(28 / 255, 0.001));
  });

  testWidgets('深色主题的浮层阴影更重', (tester) async {
    late Color shadow;
    await tester.pumpWidget(
      _host(
        theme: AppTheme.darkTheme,
        child: Builder(
          builder: (context) {
            shadow = AppMenuSurface.shadowColor(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(shadow.a, closeTo(112 / 255, 0.001));
  });
}
