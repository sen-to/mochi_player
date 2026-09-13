import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/ui/app_ui.dart';

void main() {
  testWidgets('each segment fills the control height', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: AppSegmentedControl<int>(
                value: 2,
                options: const [
                  AppSegmentedOption(value: 0, label: '浅色'),
                  AppSegmentedOption(value: 1, label: '深色', icon: Icons.dark_mode),
                  AppSegmentedOption(value: 2, label: '跟随系统', icon: Icons.computer),
                ],
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    final areas = find.descendant(of: find.byType(AppSegmentedControl<int>), matching: find.byType(AppClickableArea));

    expect(areas, findsNWidgets(3));
    for (final element in areas.evaluate()) {
      expect(tester.getSize(find.byWidget(element.widget)).height, 32);
    }
    expect(find.byType(Icon), findsNWidgets(2));
    expect(
      tester.getSemantics(find.text('跟随系统')),
      matchesSemantics(
        label: '跟随系统',
        textDirection: TextDirection.ltr,
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('浅色')),
      matchesSemantics(
        label: '浅色',
        textDirection: TextDirection.ltr,
        isButton: true,
        hasSelectedState: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('is disabled when onChanged is omitted', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: 240,
              child: AppSegmentedControl<int>(
                value: 0,
                options: [
                  AppSegmentedOption(value: 0, label: '第一项'),
                  AppSegmentedOption(value: 1, label: '第二项'),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final areas = tester.widgetList<AppClickableArea>(
      find.descendant(of: find.byType(AppSegmentedControl<int>), matching: find.byType(AppClickableArea)),
    );
    expect(areas.every((area) => area.onTap == null), isTrue);
  });

  testWidgets('toolbar appearance uses neutral toolbar surfaces', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: AppSegmentedControl<int>(
            value: 0,
            appearance: AppSegmentedControlAppearance.toolbar,
            options: const [
              AppSegmentedOption.icon(value: 0, label: '列表视图', icon: Icons.view_list_outlined),
              AppSegmentedOption.icon(value: 1, label: '网格视图', icon: Icons.grid_view_outlined),
            ],
            onChanged: (_) {},
          ),
        ),
      ),
    );

    final context = tester.element(find.byType(AppSegmentedControl<int>));
    final areas = tester.widgetList<AppClickableArea>(
      find.descendant(of: find.byType(AppSegmentedControl<int>), matching: find.byType(AppClickableArea)),
    );
    expect(areas.first.backgroundColor, AppColors.hoverSurface(context));
    expect(areas.last.backgroundColor, Colors.transparent);
  });

  testWidgets('icon options keep labels for tooltip and semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    var value = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SizedBox(
            width: 80,
            child: AppSegmentedControl<int>(
              value: value,
              options: const [
                AppSegmentedOption.icon(value: 0, label: '列表视图', icon: Icons.view_list_outlined),
                AppSegmentedOption.icon(value: 1, label: '网格视图', icon: Icons.grid_view_outlined),
              ],
              onChanged: (nextValue) => value = nextValue,
            ),
          ),
        ),
      ),
    );

    expect(find.text('列表视图'), findsNothing);
    expect(find.text('网格视图'), findsNothing);
    expect(find.byTooltip('列表视图'), findsOneWidget);
    expect(find.byTooltip('网格视图'), findsOneWidget);
    expect(
      tester.getSemantics(find.byIcon(Icons.view_list_outlined)),
      matchesSemantics(
        label: '列表视图',
        textDirection: TextDirection.ltr,
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );

    await tester.tap(find.byTooltip('网格视图'));
    expect(value, 1);
    semantics.dispose();
  });
}
