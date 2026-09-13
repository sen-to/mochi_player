import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/playback/presentation/widgets/player_popup_menu.dart';

void main() {
  testWidgets('opens a rounded player menu above its control', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _testApp(
        PlayerPopupMenuButton(
          menuWidth: 280,
          menuBuilder: (context, close) => PlayerPopupMenuPanel(
            title: '字幕',
            children: [
              PlayerPopupMenuItem(label: '自动', selected: true, onPressed: close),
              const PlayerPopupMenuDivider(),
              PlayerPopupMenuSwitchItem(
                title: '使用 Mochi 字幕样式',
                subtitle: '忽略字幕文件自带的字体与颜色',
                value: true,
                onChanged: (_) {},
              ),
            ],
          ),
          child: const SizedBox(key: ValueKey('menu-trigger'), width: 34, height: 34),
        ),
      ),
    );

    await tester.tap(find.byType(PlayerPopupMenuButton));
    await tester.pumpAndSettle();

    expect(find.text('字幕'), findsOneWidget);
    expect(find.text('自动'), findsOneWidget);
    expect(find.text('使用 Mochi 字幕样式'), findsOneWidget);
    expect(find.byType(PopupMenuButton), findsNothing);

    final panel = tester.widget<ClipRRect>(find.byKey(const ValueKey('player-popup-menu-panel')));
    expect(panel.borderRadius, BorderRadius.circular(PlayerPopupMenuMetrics.panelRadius));
    expect(find.byKey(const ValueKey('player-popup-menu-pointer')), findsOne);

    expect(
      tester.getBottomRight(find.byKey(const ValueKey('player-popup-menu-pointer'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const ValueKey('menu-trigger'))).dy),
    );
  });

  testWidgets('selects an item and closes the player menu', (tester) async {
    var selected = false;
    final visibilityChanges = <bool>[];
    await tester.pumpWidget(
      _testApp(
        PlayerPopupMenuButton(
          menuWidth: 160,
          onVisibilityChanged: visibilityChanges.add,
          menuBuilder: (context, close) => PlayerPopupMenuPanel(
            title: '播放速度',
            children: [
              PlayerPopupMenuItem(
                label: '1.5X',
                onPressed: () {
                  selected = true;
                  close();
                },
              ),
            ],
          ),
          child: const SizedBox(key: ValueKey('menu-trigger'), width: 34, height: 34),
        ),
      ),
    );

    await tester.tap(find.byType(PlayerPopupMenuButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1.5X'));
    await tester.pumpAndSettle();

    expect(selected, isTrue);
    expect(visibilityChanges, [true, false]);
    expect(find.text('播放速度'), findsNothing);
  });

  testWidgets('starts a short fade immediately when blank space is clicked', (tester) async {
    await tester.pumpWidget(
      _testApp(
        PlayerPopupMenuButton(
          menuWidth: 160,
          menuBuilder: (context, close) => const PlayerPopupMenuPanel(title: '播放速度', children: []),
          child: const SizedBox(width: 34, height: 34),
        ),
      ),
    );

    await tester.tap(find.byType(PlayerPopupMenuButton));
    await tester.pumpAndSettle();
    expect(find.text('播放速度'), findsOneWidget);

    final barrier = find.byKey(const ValueKey('player-popup-menu-barrier'));
    final pointer = await tester.startGesture(tester.getCenter(barrier));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    final opacity = tester.widget<FadeTransition>(find.byKey(const ValueKey('player-popup-menu-fade')));
    expect(opacity.opacity.value, lessThan(1));

    await pointer.up();
    await tester.pumpAndSettle();
    expect(find.text('播放速度'), findsNothing);
  });

  testWidgets('rebuilds an open menu when its switch value changes', (tester) async {
    var value = false;
    await tester.pumpWidget(
      _testApp(
        StatefulBuilder(
          builder: (context, setState) => PlayerPopupMenuButton(
            menuWidth: 280,
            menuBuilder: (context, close) => PlayerPopupMenuPanel(
              title: '字幕',
              children: [
                PlayerPopupMenuSwitchItem(
                  title: '使用 Mochi 字幕样式',
                  subtitle: '忽略字幕文件自带的字体与颜色',
                  value: value,
                  onChanged: (nextValue) {
                    setState(() => value = nextValue);
                  },
                ),
              ],
            ),
            child: const SizedBox(width: 34, height: 34),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(PlayerPopupMenuButton));
    await tester.pumpAndSettle();
    expect(tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch)).value, isFalse);

    await tester.tap(find.text('使用 Mochi 字幕样式'));
    await tester.pumpAndSettle();

    expect(value, isTrue);
    expect(tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch)).value, isTrue);
  });
}

Widget _testApp(Widget child) {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    home: Scaffold(
      backgroundColor: Colors.black,
      body: Align(alignment: Alignment.bottomCenter, child: child),
    ),
  );
}
