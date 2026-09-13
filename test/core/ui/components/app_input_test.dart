import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/core/ui/components/input/internal/app_text_context_menu.dart';
import 'package:mochi_player/core/ui/components/overlay/internal/menu_parts.dart';

void main() {
  testWidgets('uses a subtle neutral surface when disabled in dark mode', (tester) async {
    final controller = TextEditingController(text: 'http://127.0.0.1:7897');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: SizedBox(width: 320, child: AppInput(controller: controller, enabled: false)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(AppInput));
    final surfaces = tester
        .widgetList<DecoratedBox>(find.descendant(of: find.byType(AppInput), matching: find.byType(DecoratedBox)))
        .map((box) => box.decoration)
        .whereType<BoxDecoration>();
    expect(surfaces.any((surface) => surface.color == AppColors.subtleSurface(context)), isTrue);

    final textField = tester.widget<CupertinoTextField>(find.byType(CupertinoTextField));
    expect(textField.decoration?.color, Colors.transparent);
    expect(textField.style?.color, AppColors.textSecondary(context));

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('releases focus and selection highlight when disabled', (tester) async {
    final controller = TextEditingController(text: 'http://127.0.0.1:7897');
    final focusNode = FocusNode();
    var enabled = true;
    late StateSetter updateHost;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              updateHost = setState;
              return SizedBox(
                width: 320,
                child: AppInput(controller: controller, focusNode: focusNode, enabled: enabled),
              );
            },
          ),
        ),
      ),
    );

    focusNode.requestFocus();
    controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    updateHost(() => enabled = false);
    await tester.pumpAndSettle();

    expect(focusNode.hasFocus, isFalse);
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.selectionColor, isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    focusNode.dispose();
  });

  testWidgets('uses the width provided by its parent', (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SizedBox(width: 320, child: AppInput(controller: controller)),
        ),
      ),
    );

    expect(tester.getSize(find.byType(AppInput)).width, 320);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('reports a committed edit when focus leaves the field', (tester) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    var focusLostCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: AppInput(controller: controller, focusNode: focusNode, onFocusLost: () => focusLostCount++),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();
    focusNode.unfocus();
    await tester.pump();

    expect(focusLostCount, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    focusNode.dispose();
  });

  testWidgets('uses the compact application text context menu', (tester) async {
    final controller = TextEditingController(text: 'admin');
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: AppInput(controller: controller)),
      ),
    );

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse, buttons: kSecondaryMouseButton);
    final inputCenter = tester.getCenter(find.byType(CupertinoTextField));
    await mouse.addPointer(location: inputCenter);
    await mouse.down(inputCenter);
    await mouse.up();
    await tester.pumpAndSettle();

    expect(find.byType(AppTextContextMenu), findsOneWidget);
    expect(find.byType(MenuPanel), findsOneWidget);
    expect(find.byType(MenuOptionRow), findsWidgets);
    final labels = tester
        .widgetList<Text>(find.descendant(of: find.byType(AppTextContextMenu), matching: find.byType(Text)))
        .map((text) => text.data)
        .whereType<String>()
        .toList();
    const localizedLabels = {'剪切', '复制', '粘贴', '全选', '删除', '查询', '网页搜索', '分享', '实况文本', '操作'};
    expect(labels, isNotEmpty);
    expect(labels.every(localizedLabels.contains), isTrue);

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.focusNode.hasFocus, isTrue);
    await mouse.moveTo(tester.getCenter(find.text(labels.first)));
    await tester.pumpAndSettle();

    expect(editable.focusNode.hasFocus, isTrue);
    expect(find.byType(AppTextContextMenu), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.byType(AppTextContextMenu), findsOneWidget);
    expect(find.byType(MenuOptionRow), findsWidgets);
    await mouse.removePointer();

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('password context menu always exposes paste and select all', (tester) async {
    final controller = TextEditingController(text: 'secret');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(body: AppInput(controller: controller, obscureText: true)),
      ),
    );

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse, buttons: kSecondaryMouseButton);
    final inputCenter = tester.getCenter(find.byType(CupertinoTextField));
    await mouse.addPointer(location: inputCenter);
    await mouse.down(inputCenter);
    await mouse.up();
    await tester.pumpAndSettle();

    expect(find.byType(AppTextContextMenu), findsOneWidget);
    expect(find.text('粘贴'), findsOneWidget);
    expect(find.text('全选'), findsOneWidget);
    expect(find.text('剪切'), findsNothing);
    expect(find.text('复制'), findsNothing);

    await mouse.removePointer();
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('search input composes the shared input', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Align(child: SizedBox(width: 280, child: AppSearchInput())),
        ),
      ),
    );

    expect(find.byType(AppSearchInput), findsOneWidget);
    expect(find.byType(AppInput), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.search), findsOneWidget);
    expect(tester.getSize(find.byType(AppSearchInput)).width, 280);

    final textField = tester.widget<CupertinoTextField>(find.byType(CupertinoTextField));
    expect(textField.textAlignVertical, TextAlignVertical.center);
    expect(textField.padding, const EdgeInsets.only(top: 4));
    expect(textField.style?.height, 1);
    expect(textField.placeholderStyle?.height, 1);
    expect(textField.strutStyle?.forceStrutHeight, isTrue);
    expect(textField.strutStyle?.height, 1);
  });

  testWidgets('search input focuses itself with Ctrl+K', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: SizedBox(width: 240, child: AppSearchInput())),
      ),
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyK);
    await tester.pump();

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.focusNode.hasFocus, isTrue);

    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  });

  testWidgets('places a suffix inside the standard input boundary', (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SizedBox(
            width: 240,
            child: AppInput(
              controller: controller,
              suffix: const SizedBox(key: ValueKey('input_suffix'), width: 22, height: 22),
            ),
          ),
        ),
      ),
    );

    final inputRect = tester.getRect(find.byType(AppInput));
    final suffixRect = tester.getRect(find.byKey(const ValueKey('input_suffix')));
    expect(suffixRect.right, lessThanOrEqualTo(inputRect.right));
    expect(suffixRect.center.dy, inputRect.center.dy);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}
