import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/features/playback/presentation/controllers/player_window_close_coordinator.dart';

void main() {
  test('flushes the active player callback before the window closes', () async {
    final coordinator = PlayerWindowCloseCoordinator();
    var flushCount = 0;
    coordinator.registerProgressFlusher(() async {
      flushCount++;
    });

    await coordinator.flushProgress();
    coordinator.unregisterProgressFlusher();
    await coordinator.flushProgress();

    expect(flushCount, 1);
  });

  test(
    'shares an in-flight final flush between repeated close requests',
    () async {
      final coordinator = PlayerWindowCloseCoordinator();
      var flushCount = 0;
      final finishFlush = Completer<void>();
      coordinator.registerProgressFlusher(() async {
        flushCount++;
        await finishFlush.future;
      });

      final firstFlush = coordinator.flushProgress();
      final secondFlush = coordinator.flushProgress();
      await Future<void>.delayed(Duration.zero);
      expect(flushCount, 1);

      finishFlush.complete();
      await Future.wait([firstFlush, secondFlush]);
    },
  );
}
