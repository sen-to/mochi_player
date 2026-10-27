// 【行为测试】验证协调进度保存、页面退役、会话释放及窗口关闭。
// 测试对象的职责边界：各阶段设有等待边界，页面不直接实现原生窗口销毁。

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/features/playback/ui/controllers/player_window_close_coordinator.dart';

void main() {
  test('a hung resource release is reported and does not skip view detachment', () async {
    final coordinator = PlayerWindowCloseCoordinator(resourceTimeout: const Duration(milliseconds: 5));
    var detached = false;
    coordinator.registerResourceReleaser(() => Completer<void>().future);
    final report = await coordinator.prepareClose(
      settleSession: () async {},
      closeSession: () async {},
      detachView: () async => detached = true,
    );
    expect(report.released, isFalse);
    expect(report.failedStages, ['resources']);
    expect(detached, isTrue);
  });
  test('an unmounted page still closes its session before detaching the view', () async {
    final coordinator = PlayerWindowCloseCoordinator();
    final events = <String>[];
    final report = await coordinator.prepareClose(
      settleSession: () async {},
      closeSession: () async => events.add('session'),
      detachView: () async => events.add('detach'),
    );
    expect(report.released, isTrue);
    expect(events, ['session', 'detach']);
  });

  test('a hung session close stays inside the resource deadline', () async {
    final coordinator = PlayerWindowCloseCoordinator(resourceTimeout: const Duration(milliseconds: 5));
    var detached = false;
    final report = await coordinator.prepareClose(
      settleSession: () async {},
      closeSession: () => Completer<void>().future,
      detachView: () async => detached = true,
    );
    expect(report.released, isFalse);
    expect(report.failedStages, ['resources']);
    expect(detached, isTrue);
  });

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

  test('preparation confirms persistence and resource release before view detach', () async {
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
      closeSession: () async {},
      detachView: () async => events.add('detach'),
    );
    final repeated = coordinator.prepareClose(
      settleSession: () async => fail('duplicate close'),
      closeSession: () async => fail('duplicate close'),
      detachView: () async => fail('duplicate close'),
    );
    expect(identical(report, repeated), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(events, ['settle', 'save']);
    save.complete();
    final result = await report;
    expect(result.saved && result.released, isTrue);
    expect(result.failedStages, isEmpty);
    expect(events, ['settle', 'save', 'release', 'detach']);
  });

  test('failed final write is reported honestly and does not skip resource cleanup', () async {
    final coordinator = PlayerWindowCloseCoordinator();
    var released = false;
    coordinator.registerProgressFlusher(() async => throw StateError('write failed'));
    coordinator.registerResourceReleaser(() async => released = true);
    final report = await coordinator.prepareClose(
      settleSession: () async {},
      closeSession: () async {},
      detachView: () async {},
    );
    expect(report.saved, isFalse);
    expect(report.released, isTrue);
    expect(report.failedStages, ['progress']);
    expect(released, isTrue);
  });

  test('a hung progress flusher reaches its deadline and releases remaining resources', () async {
    final coordinator = PlayerWindowCloseCoordinator(stageTimeout: const Duration(milliseconds: 5));
    coordinator.registerProgressFlusher(() => Completer<void>().future);
    coordinator.registerResourceReleaser(() async {});
    final report = await coordinator.prepareClose(
      settleSession: () async {},
      closeSession: () async {},
      detachView: () async {},
    );
    expect(report.saved, isFalse);
    expect(report.failedStages, ['progress']);
  });
}
