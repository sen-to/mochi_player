import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/core/ui/components/overlay/internal/menu_parts.dart';

void main() {
  testWidgets('opens the anchored menu and selects an option', (tester) async {
    String? selected;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: AppDropdown<String>(
              tooltip: '操作',
              onSelected: (value) => selected = value,
              options: const [AppDropdownOption(value: 'open', label: '打开')],
              trigger: const SizedBox(width: 36, height: 34, child: Icon(AppIcons.more)),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(InkWell), findsNothing);
    expect(find.byType(PopupMenuItem<String>), findsNothing);

    await tester.tap(find.byIcon(AppIcons.more));
    await tester.pumpAndSettle();

    expect(find.byType(MenuOptionRow), findsOneWidget);

    await tester.tap(find.text('打开'));
    await tester.pump();
    expect(selected, 'open');
    await tester.pumpAndSettle();

    expect(find.byType(MenuOptionRow), findsNothing);
  });

  testWidgets('stays open when the pointer moves from trigger to an option', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: AppDropdown<String>(
              tooltip: '操作',
              onSelected: (_) {},
              options: const [AppDropdownOption(value: 'open', label: '打开')],
              trigger: const SizedBox(width: 80, height: 34, child: Text('菜单')),
            ),
          ),
        ),
      ),
    );

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text('菜单')));
    await tester.pump();
    await mouse.down(tester.getCenter(find.text('菜单')));
    await mouse.up();
    await tester.pumpAndSettle();
    expect(find.byType(MenuOptionRow), findsOneWidget);

    final anchorRect = tester.getRect(find.byType(MenuAnchor));
    final optionRect = tester.getRect(find.byType(MenuOptionRow));
    expect(optionRect.left, closeTo(anchorRect.left + 6, 0.1));
    expect(optionRect.top, closeTo(anchorRect.bottom + 12, 0.1));

    await mouse.moveTo(tester.getCenter(find.text('打开')));
    await tester.pumpAndSettle();

    expect(find.byType(MenuOptionRow), findsOneWidget);
    await mouse.removePointer();
  });

  testWidgets('can align an action menu to the trigger trailing edge', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: AppDropdown<String>(
              menuWidth: 140,
              menuAlignment: AppDropdownMenuAlignment.end,
              onSelected: (_) {},
              options: const [AppDropdownOption(value: 'copy', label: '复制路径')],
              trigger: const SizedBox(width: 38, height: 34, child: Icon(AppIcons.more)),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(AppIcons.more));
    await tester.pumpAndSettle();

    final anchorRect = tester.getRect(find.byType(MenuAnchor));
    final optionRect = tester.getRect(find.byType(MenuOptionRow));
    expect(optionRect.right, closeTo(anchorRect.right - 6, 0.1));
    expect(optionRect.top, closeTo(anchorRect.bottom + 12, 0.1));
  });
}
