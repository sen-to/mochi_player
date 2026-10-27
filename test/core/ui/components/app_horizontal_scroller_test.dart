// 【行为测试】验证为横向内容提供前后滚动按钮及滚动状态。
// 测试对象的职责边界：组件持有并释放自己的滚动控制器。

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/l10n/l10n.dart';

void main() {
  testWidgets('scrolls its content by a viewport-relative distance', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 100,
            child: AppHorizontalScroller(
              controller: controller,
              contentBuilder: (context, providedController) {
                expect(providedController, same(controller));
                return ListView.builder(
                  controller: providedController,
                  scrollDirection: Axis.horizontal,
                  itemCount: 10,
                  itemBuilder: (_, _) => const SizedBox(width: 120),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byType(AppHorizontalScroller)));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
    await tester.pumpAndSettle();

    expect(controller.offset, closeTo(320 * 0.8, 1));
    await mouse.removePointer();
  });

  testWidgets('rebinds listeners when its controller changes', (tester) async {
    final firstController = ScrollController();
    final secondController = ScrollController();
    late StateSetter update;
    var activeController = firstController;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return SizedBox(
                width: 320,
                height: 100,
                child: AppHorizontalScroller(
                  controller: activeController,
                  contentBuilder: (context, controller) => ListView(
                    controller: controller,
                    scrollDirection: Axis.horizontal,
                    children: const [SizedBox(width: 800)],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(firstController.hasClients, isTrue);

    update(() => activeController = secondController);
    await tester.pumpAndSettle();

    expect(firstController.hasClients, isFalse);
    expect(secondController.hasClients, isTrue);
    secondController.jumpTo(40);
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    firstController.dispose();
    secondController.dispose();
  });
}
