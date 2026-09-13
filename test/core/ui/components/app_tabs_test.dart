import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/ui/app_ui.dart';

void main() {
  testWidgets('reports the selected tab and exposes selection semantics', (tester) async {
    var selected = 'appearance';
    late StateSetter updateHost;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: StatefulBuilder(
          builder: (context, setState) {
            updateHost = setState;
            return SizedBox(
              width: 300,
              child: AppTabs<String>(
                value: selected,
                onChanged: (value) => updateHost(() => selected = value),
                tabs: const [
                  AppTab(value: 'appearance', label: '外观', icon: Icons.light_mode_outlined),
                  AppTab(value: 'playback', label: '播放', icon: Icons.play_circle_outline),
                ],
              ),
            );
          },
        ),
      ),
    );

    expect(
      tester.getSemantics(find.text('外观')),
      matchesSemantics(isButton: true, hasSelectedState: true, isSelected: true, hasTapAction: true),
    );
    final indicatorBefore = tester.getRect(find.byKey(const ValueKey('app_tabs_indicator')));
    await tester.tap(find.text('播放'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(selected, 'playback');
    expect(tester.getRect(find.byKey(const ValueKey('app_tabs_indicator'))).left, greaterThan(indicatorBefore.left));
  });
}
