import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/platform/window_controls_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('mochi_player/window_controls');
  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('positions native macOS buttons through the platform bridge', () async {
    final controller = WindowControlsController();

    await controller.positionNativeWindowButtons();

    expect(calls.single.method, 'positionNativeWindowButtons');
  });

  test('publishes mini-player state and updates native visibility', () async {
    final controller = WindowControlsController();
    var notifications = 0;
    controller.addListener(() => notifications++);

    await controller.setMiniPlayerMode(true);

    expect(controller.isMiniPlayer, isTrue);
    expect(notifications, 1);
    expect(calls.single.method, 'setNativeWindowButtonsVisible');
    expect(calls.single.arguments, isFalse);
  });
}
