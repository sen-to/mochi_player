import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/ui/app_ui.dart';

void main() {
  testWidgets('uses the hover color space for transparent areas', (tester) async {
    const areaKey = Key('clickable-area');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: AppClickableArea(
                key: areaKey,
                onTap: () {},
                borderRadius: BorderRadius.zero,
                hoverColor: AppColors.hoverSurface(context),
                child: const SizedBox(width: 80, height: 40),
              ),
            ),
          ),
        ),
      ),
    );

    final context = tester.element(find.byKey(areaKey));
    final hoverColor = AppColors.hoverSurface(context);
    final container = tester.widget<Container>(
      find.descendant(of: find.byKey(areaKey), matching: find.byType(Container)),
    );
    final decoration = container.decoration! as BoxDecoration;

    expect(decoration.color, hoverColor.withAlpha(0));
  });

  testWidgets('keeps the hover color unchanged while pressed', (tester) async {
    const areaKey = Key('opaque-clickable-area');
    const backgroundColor = Color(0xFF202023);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Center(
            child: AppClickableArea(
              key: areaKey,
              onTap: () {},
              borderRadius: BorderRadius.zero,
              backgroundColor: backgroundColor,
              hoverColor: const Color(0x16F5F5F7),
              child: const SizedBox(width: 80, height: 40),
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    final center = tester.getCenter(find.byKey(areaKey));
    await gesture.moveTo(center);
    await tester.pumpAndSettle();

    Color areaColor() {
      final container = tester.widget<Container>(
        find.descendant(of: find.byKey(areaKey), matching: find.byType(Container)),
      );
      return (container.decoration! as BoxDecoration).color!;
    }

    final expectedHoverColor = Color.alphaBlend(const Color(0x16F5F5F7), backgroundColor);
    expect(areaColor(), expectedHoverColor);

    await gesture.down(center);
    await tester.pump();
    expect(areaColor(), expectedHoverColor);

    await gesture.up();
    await gesture.removePointer();
  });

  testWidgets('applies external state colors without an implicit transition', (tester) async {
    const areaKey = Key('stateful-clickable-area');
    const selectedColor = Color(0xFF35323F);
    late StateSetter updateState;
    var selected = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              updateState = setState;
              return AppClickableArea(
                key: areaKey,
                onTap: () {},
                borderRadius: BorderRadius.zero,
                backgroundColor: selected ? selectedColor : Colors.transparent,
                hoverColor: selected ? Colors.transparent : AppColors.hoverSurface(context),
                child: const SizedBox(width: 80, height: 40),
              );
            },
          ),
        ),
      ),
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(tester.getCenter(find.byKey(areaKey)));
    await tester.pumpAndSettle();

    updateState(() => selected = true);
    await tester.pump();

    final container = tester.widget<Container>(
      find.descendant(of: find.byKey(areaKey), matching: find.byType(Container)),
    );
    expect((container.decoration! as BoxDecoration).color, selectedColor);

    await gesture.removePointer();
  });

  testWidgets('supports desktop keyboard activation', (tester) async {
    var activations = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppClickableArea(
            onTap: () => activations++,
            borderRadius: BorderRadius.zero,
            hoverColor: Colors.black12,
            child: const SizedBox(width: 80, height: 40),
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);

    expect(activations, 2);
  });
}
