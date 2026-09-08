import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/ui/app_ui.dart';

void main() {
  testWidgets('translates the public step API into discrete positions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: AppSlider(
            value: 20,
            min: 0,
            max: 100,
            step: 5,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(tester.widget<Slider>(find.byType(Slider)).divisions, 20);
  });

  testWidgets('uses one native-painted tooltip for hover and drag', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: AppSlider(
                value: 39,
                min: 0,
                max: 100,
                tooltipFormatter: (value) => '${value.round()}%',
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.widget<Slider>(find.byType(Slider)).label, '39%');
    expect(tester.getSemantics(find.bySemanticsLabel('39%')).value, '39%');
    semantics.dispose();

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(_thumbPosition(tester, value: 39));
    await tester.pump(const Duration(milliseconds: 120));

    final sliderTheme = tester.widget<SliderTheme>(find.byType(SliderTheme));
    expect(
      sliderTheme.data.overlayShape!.getPreferredSize(true, false),
      const Size.square(32),
    );
    expect(sliderTheme.data.showValueIndicator, ShowValueIndicator.never);
    expect(tester.takeException(), isNull);

    await mouse.down(_thumbPosition(tester, value: 39));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await mouse.up();

    await mouse.removePointer();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });

  testWidgets('updates a visible tooltip after the slider value changes', (
    tester,
  ) async {
    var value = 39.0;
    late StateSetter update;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return Center(
                child: SizedBox(
                  width: 300,
                  child: AppSlider(
                    value: value,
                    min: 0,
                    max: 100,
                    onChanged: (_) {},
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(_thumbPosition(tester, value: 39));
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.widget<Slider>(find.byType(Slider)).label, '39');

    update(() => value = 40);
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(tester.widget<Slider>(find.byType(Slider)).label, '40');

    await mouse.removePointer();
  });

  testWidgets('updates its visual value in the same drag frame', (
    tester,
  ) async {
    double? reportedValue;
    var value = 20.0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: StatefulBuilder(
                builder: (context, setState) {
                  return AppSlider(
                    value: value,
                    min: 0,
                    max: 100,
                    onChanged: (nextValue) {
                      reportedValue = nextValue;
                      setState(() => value = nextValue);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: _thumbPosition(tester, value: 20));
    await mouse.down(_thumbPosition(tester, value: 20));
    await mouse.moveBy(const Offset(60, 0));
    await tester.pump();

    expect(reportedValue, isNotNull);
    expect(reportedValue!, greaterThan(20));
    expect(tester.widget<Slider>(find.byType(Slider)).value, reportedValue);
    final label = tester.widget<Slider>(find.byType(Slider)).label;
    expect(double.parse(label!), closeTo(reportedValue!, 0.01));

    await mouse.up();
    await mouse.removePointer();
  });
}

Offset _thumbPosition(
  WidgetTester tester, {
  required double value,
  double min = 0,
  double max = 100,
}) {
  final rect = tester.getRect(find.byType(AppSlider));
  const inset = 9.0;
  final progress = (value - min) / (max - min);
  return Offset(
    rect.left + inset + (rect.width - inset * 2) * progress,
    rect.center.dy,
  );
}
