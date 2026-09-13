import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/ui/app_ui.dart';

void main() {
  testWidgets('keeps selected overlay button colors neutral', (tester) async {
    const accent = Color(0xFFB45F73);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: AppButton(
            onPressed: _noop,
            icon: Icons.favorite,
            label: '已收藏',
            variant: AppButtonVariant.secondary,
            appearance: AppAppearance.overlay,
            selected: true,
            accentColor: accent,
          ),
        ),
      ),
    );

    final container = tester.widget<Container>(
      find.descendant(of: find.byType(AppButton), matching: find.byType(Container)),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, Colors.black.withAlpha(76));
    expect((decoration.border! as Border).top.color, Colors.white.withAlpha(58));
    expect(tester.widget<Icon>(find.byIcon(Icons.favorite)).color, accent);
    expect(tester.widget<Text>(find.text('已收藏')).style?.color, Colors.white.withAlpha(235));
  });

  testWidgets('supports an icon-only button through the same API', (tester) async {
    var pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: AppButton.icon(onPressed: () => pressed = true, icon: Icons.visibility_outlined, tooltip: '显示'),
        ),
      ),
    );

    expect(find.byType(AppButton), findsOneWidget);
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    expect(pressed, isTrue);
  });

  testWidgets('supports desktop keyboard activation', (tester) async {
    var pressed = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: AppButton(onPressed: () => pressed++, label: '确定', size: AppButtonSize.compact),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(pressed, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(pressed, 2);
  });
}

void _noop() {}
