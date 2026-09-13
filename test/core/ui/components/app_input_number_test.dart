import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/ui/app_ui.dart';

void main() {
  testWidgets('changes by the configured step and respects bounds', (tester) async {
    var value = 10;
    late StateSetter updateHost;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              updateHost = setState;
              return SizedBox(
                width: 200,
                child: AppInputNumber(
                  value: value,
                  min: 0,
                  max: 20,
                  step: 5,
                  onChanged: (nextValue) => updateHost(() => value = nextValue),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('增加'));
    await tester.pump();
    expect(value, 15);

    await tester.tap(find.byTooltip('减少'));
    await tester.pump();
    expect(value, 10);

    updateHost(() => value = 20);
    await tester.pump();
    final incrementButton = find.descendant(of: find.byTooltip('增加'), matching: find.byType(AppClickableArea));
    expect(tester.widget<AppClickableArea>(incrementButton).onTap, isNull);
    expect(find.byType(ClipRRect), findsOneWidget);
  });

  testWidgets('normalizes typed values when editing completes', (tester) async {
    var value = 10;
    late StateSetter updateHost;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              updateHost = setState;
              return SizedBox(
                width: 200,
                child: AppInputNumber(
                  value: value,
                  min: 0,
                  max: 20,
                  onChanged: (nextValue) => updateHost(() => value = nextValue),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(CupertinoTextField));
    await tester.enterText(find.byType(CupertinoTextField), '99');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(value, 20);
    expect(find.text('20'), findsOneWidget);
  });
}
