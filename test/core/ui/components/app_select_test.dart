import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/core/ui/components/overlay/internal/menu_parts.dart';

void main() {
  Widget buildSelect({ValueChanged<int>? onChanged}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 92,
            child: AppSelect<int>(
              value: 1,
              options: const [
                AppSelectOption(value: 1, label: '第一项'),
                AppSelectOption(value: 2, label: '第二项'),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('uses its design-system height and its parent width', (tester) async {
    await tester.pumpWidget(buildSelect(onChanged: (_) {}));

    expect(tester.getSize(find.byType(AppSelect<int>)), const Size(92, 32));
  });

  testWidgets('reports a selection on the next frame', (tester) async {
    int? selected;
    await tester.pumpWidget(buildSelect(onChanged: (value) => selected = value));

    await tester.tap(find.text('第一项'));
    await tester.pumpAndSettle();
    final selectRect = tester.getRect(find.byType(AppSelect<int>));
    final firstOptionRect = tester.getRect(find.byType(MenuOptionRow).first);
    expect(firstOptionRect.left, closeTo(selectRect.left + 6, 0.1));
    expect(firstOptionRect.right, closeTo(selectRect.right - 6, 0.1));
    await tester.tap(find.text('第二项'));
    await tester.pump();

    expect(selected, 2);
  });

  testWidgets('is disabled when onChanged is omitted', (tester) async {
    await tester.pumpWidget(buildSelect());

    await tester.tap(find.text('第一项'));
    await tester.pumpAndSettle();

    expect(find.byType(MenuOptionRow), findsNothing);
  });
}
