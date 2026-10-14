import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/app/application/application_exit_coordinator.dart';

void main() {
  test('keeps the host alive for final player save, then cleanup, then exits once', () async {
    final events = <String>[];
    final finalSave = Completer<void>();
    final coordinator = ApplicationExitCoordinator(
      beginShutdown: () => events.add('block new work'),
      closePlayers: () async {
        events.add('save player');
        await finalSave.future;
        events.add('player closed');
      },
      cleanUp: () async => events.add('close main database'),
      exitProcess: () => events.add('exit process'),
      onFailure: (stage, error) => fail('$stage: $error'),
    );
    final first = coordinator.requestExit();
    final second = coordinator.requestExit();
    expect(identical(first, second), isTrue);
    expect(coordinator.isExiting, isTrue);
    expect(events, ['block new work', 'save player']);
    finalSave.complete();
    await first;
    await coordinator.requestExit();
    expect(events, ['block new work', 'save player', 'player closed', 'close main database', 'exit process']);
  });

  test('unresponsive child and cleanup both have deadlines before process exit', () async {
    final events = <String>[];
    final coordinator = ApplicationExitCoordinator(
      beginShutdown: () {},
      closePlayers: () => Completer<void>().future,
      cleanUp: () => Completer<void>().future,
      exitProcess: () => events.add('exit'),
      onFailure: (stage, error) {
        expect(error, isA<TimeoutException>());
        events.add(stage);
      },
      playerTimeout: const Duration(milliseconds: 5),
      cleanupTimeout: const Duration(milliseconds: 5),
    );
    await coordinator.requestExit();
    expect(events, ['player shutdown', 'application cleanup', 'exit']);
  });

  test('synchronous and asynchronous cleanup failures cannot leave a process running', () async {
    final events = <String>[];
    final coordinator = ApplicationExitCoordinator(
      beginShutdown: () => throw StateError('begin failed'),
      closePlayers: () => throw StateError('player cleanup failed'),
      cleanUp: () async => throw StateError('database failed'),
      exitProcess: () => events.add('exit'),
      onFailure: (stage, error) => events.add(stage),
    );
    await coordinator.requestExit();
    expect(events, ['begin shutdown', 'player shutdown', 'application cleanup', 'exit']);
  });
}
