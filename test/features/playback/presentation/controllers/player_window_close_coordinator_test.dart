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

  test('shares an in-flight final flush between repeated close requests', () async {
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
  });

  test('preparation confirms persistence and resource release before database close', () async {
    final coordinator = PlayerWindowCloseCoordinator();
    final events = <String>[];
    final save = Completer<void>();
    coordinator.registerProgressFlusher(() async {
      events.add('save');
      await save.future;
    });
    coordinator.registerResourceReleaser(() async => events.add('release'));
    final report = coordinator.prepareClose(
      settleSession: () async => events.add('settle'),
      detachView: () async => events.add('detach'),
      closeDatabase: () async => events.add('database'),
    );
    final repeated = coordinator.prepareClose(
      settleSession: () async => fail('duplicate close'),
      detachView: () async => fail('duplicate close'),
      closeDatabase: () async => fail('duplicate close'),
    );
    expect(identical(report, repeated), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(events, ['settle', 'save']);
    save.complete();
    expect(await report, {'prepared': true, 'saved': true, 'released': true, 'failedStages': <String>[]});
    expect(events, ['settle', 'save', 'release', 'detach', 'database']);
  });

  test('failed final write is reported honestly and does not skip resource cleanup', () async {
    final coordinator = PlayerWindowCloseCoordinator();
    var released = false;
    var closedDatabase = false;
    coordinator.registerProgressFlusher(() async => throw StateError('write failed'));
    coordinator.registerResourceReleaser(() async => released = true);
    final report = await coordinator.prepareClose(
      settleSession: () async {},
      detachView: () async {},
      closeDatabase: () async => closedDatabase = true,
    );
    expect(report['saved'], isFalse);
    expect(report['released'], isTrue);
    expect(report['failedStages'], ['progress']);
    expect(released && closedDatabase, isTrue);
  });

  test('a hung progress flusher reaches its deadline and releases remaining resources', () async {
    final coordinator = PlayerWindowCloseCoordinator(stageTimeout: const Duration(milliseconds: 5));
    coordinator.registerProgressFlusher(() => Completer<void>().future);
    coordinator.registerResourceReleaser(() async {});
    final report = await coordinator.prepareClose(
      settleSession: () async {},
      detachView: () async {},
      closeDatabase: () async {},
    );
    expect(report['prepared'], isTrue);
    expect(report['saved'], isFalse);
    expect(report['failedStages'], ['progress']);
  });
}
