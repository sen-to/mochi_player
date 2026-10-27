import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/playback/application/playback_engine.dart';
import 'package:mochi_player/features/playback/presentation/widgets/player_seek_bar.dart';

import '../../../../support/fake_playback_engine.dart';

void main() {
  Widget host(FakePlaybackEngine engine) => MaterialApp(
    theme: AppTheme.darkTheme,
    home: Scaffold(
      body: Center(
        child: SizedBox(width: 500, child: PlayerSeekBar(engine: engine)),
      ),
    ),
  );

  Future<void> mount(WidgetTester tester, FakePlaybackEngine engine) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await engine.dispose();
    });
    await tester.pumpWidget(host(engine));
  }

  testWidgets('shows the current position and buffer before receiving any stream events', (tester) async {
    final engine = FakePlaybackEngine()
      ..state = const PlaybackState(
        position: Duration(seconds: 30),
        buffer: Duration(seconds: 60),
        duration: Duration(minutes: 2),
      );
    await mount(tester, engine);
    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.value, 30000);
    expect(slider.secondaryTrackValue, 60000);
    expect(slider.max, 120000);
  });

  testWidgets('hover reuses one preview and removing the seek bar removes its overlay', (tester) async {
    final engine = FakePlaybackEngine()..state = const PlaybackState(duration: Duration(minutes: 2));
    await mount(tester, engine);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    final center = tester.getCenter(find.byType(Slider));
    await mouse.moveTo(center);
    await mouse.moveTo(center + const Offset(1, 0));
    await tester.pump();
    expect(find.text('01:00'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    expect(find.text('01:00'), findsNothing);
    expect(tester.takeException(), isNull);
    await mouse.removePointer();
  });

  testWidgets('drag preview holds the chosen position and seeks only when released', (tester) async {
    final engine = FakePlaybackEngine()..state = const PlaybackState(duration: Duration(minutes: 2));
    await mount(tester, engine);
    var slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChangeStart!(45000);
    slider.onChanged!(45000);
    engine.positions.add(const Duration(seconds: 10));
    await tester.pump();
    slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.value, 45000);
    expect(find.text('00:45'), findsOneWidget);
    expect(engine.sought, isNull);
    slider.onChangeEnd!(45000);
    await tester.pump();
    expect(engine.sought, const Duration(seconds: 45));
    expect(find.text('00:45'), findsNothing);
  });

  testWidgets('replacing the engine clears the preview and switches subscriptions to the new engine', (tester) async {
    final oldEngine = FakePlaybackEngine()..state = const PlaybackState(duration: Duration(minutes: 2));
    final newEngine = FakePlaybackEngine()
      ..state = const PlaybackState(position: Duration(seconds: 20), duration: Duration(minutes: 3));
    addTearDown(newEngine.dispose);
    await mount(tester, oldEngine);
    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChangeStart!(45000);
    slider.onChanged!(45000);
    await tester.pump();
    expect(find.text('00:45'), findsOneWidget);
    await tester.pumpWidget(host(newEngine));
    // Removing an overlay during widget update marks it dirty after this frame.
    await tester.pump();
    expect(find.text('00:45'), findsNothing);
    expect(tester.widget<Slider>(find.byType(Slider)).value, 20000);
    oldEngine.positions.add(const Duration(seconds: 80));
    await tester.pump();
    expect(tester.widget<Slider>(find.byType(Slider)).value, 20000);
    newEngine.positions.add(const Duration(seconds: 50));
    await tester.pump();
    expect(tester.widget<Slider>(find.byType(Slider)).value, 50000);
    expect(oldEngine.disposeCount, 0);
    expect(newEngine.disposeCount, 0);
  });
}
