import '../../support/database_fixture.dart';
import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/app/application/application_exit_coordinator.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/infrastructure/database/app_database.dart';
import 'package:mochi_player/core/infrastructure/database/database_service.dart';
import 'package:mochi_player/core/infrastructure/database/sqlite_setup.dart';
import 'package:mochi_player/features/playback/application/playback_progress_writer.dart';
import 'package:mochi_player/features/playback/presentation/controllers/player_window_close_coordinator.dart';

void main() {
  test('queued periodic save and final snapshot survive graceful exit and reopen', () async {
    final directory = await Directory.systemTemp.createTemp('mochi_exit_test_');
    final path = File('${directory.path}/library.sqlite');
    final database = DatabaseService.withDatabase(AppDatabase(NativeDatabase(path, setup: configureSqlite)));
    await database.init();
    final file = MediaFile(
      id: 0,
      sourceId: 'source',
      path: '/test.mkv',
      fileName: 'test.mkv',
      parsedTitle: 'Test',
      addedAt: DateTime(2026),
    );
    await saveMediaFixture(database, [file]);
    final periodicStarted = Completer<void>();
    final finishPeriodic = Completer<void>();
    final events = <String>[];
    final writer = PlaybackProgressWriter((file, position, {duration}) async {
      if (position == 10000) {
        periodicStarted.complete();
        await finishPeriodic.future;
      }
      await database.updateProgress(file, position, duration: duration);
      events.add('saved:$position');
    });
    final periodic = writer.save(file, 10000, duration: 100000);
    await periodicStarted.future;
    final player = PlayerWindowCloseCoordinator()
      ..registerProgressFlusher(() => writer.save(file, 42000, duration: 100000))
      ..registerResourceReleaser(() async => events.add('released'));
    final exit = ApplicationExitCoordinator(
      beginShutdown: () => events.add('begin'),
      closePlayers: () async {
        final report = await player.prepareClose(
          settleSession: () async {},
          closeSession: () async {},
          detachView: () async {},
        );
        expect(report.saved, isTrue);
        events.add('player closed');
      },
      cleanUp: () async {
        await database.close();
        events.add('main cleanup');
      },
      exitProcess: () => events.add('exit'),
      onFailure: (stage, error) => fail('$stage: $error'),
    );
    try {
      final shuttingDown = exit.requestExit();
      await Future<void>.delayed(Duration.zero);
      expect(events, ['begin']);
      finishPeriodic.complete();
      await Future.wait([periodic, shuttingDown]);
      expect(events, ['begin', 'saved:10000', 'saved:42000', 'released', 'player closed', 'main cleanup', 'exit']);
      final reopened = DatabaseService.withDatabase(AppDatabase(NativeDatabase(path, setup: configureSqlite)));
      try {
        await reopened.init();
        final saved = (await reopened.getMediaFile('source', '/test.mkv'))!;
        expect(saved.position, 42000);
        expect(saved.duration, 100000);
      } finally {
        await reopened.close();
      }
    } finally {
      await database.close();
      await directory.delete(recursive: true);
    }
  });
}
