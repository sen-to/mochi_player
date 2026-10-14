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
    final controller = WindowControlsController(viewId: 7);

    await controller.positionNativeWindowButtons();

    expect(calls.single.method, 'positionNativeWindowButtons');
    expect(calls.single.arguments, {'viewId': 7});
  });

  test('failed native visibility change does not commit mini state and permits retry', () async {
    final controller = WindowControlsController(viewId: 7);
    addTearDown(controller.dispose);
    var fail = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      if (fail) throw PlatformException(code: 'window_operation_failed');
      return null;
    });
    await expectLater(controller.setMiniPlayerMode(true), throwsA(isA<PlatformException>()));
    expect(controller.isMiniPlayer, isFalse);
    fail = false;
    await controller.setMiniPlayerMode(true);
    expect(controller.isMiniPlayer, isTrue);
  });

  test('publishes mini-player state and updates native visibility', () async {
    final controller = WindowControlsController(viewId: 7);
    var notifications = 0;
    controller.addListener(() => notifications++);

    await controller.setMiniPlayerMode(true);

    expect(controller.isMiniPlayer, isTrue);
    expect(notifications, 1);
    expect(calls.single.method, 'setNativeWindowButtonsVisible');
    expect(calls.single.arguments, {'viewId': 7, 'visible': false});
  });
}
