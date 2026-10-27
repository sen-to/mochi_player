import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/app/bootstrap/application_dependencies.dart';
import 'package:mochi_player/core/domain/app_failure.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/infrastructure/database/app_database.dart';
import 'package:mochi_player/core/infrastructure/database/database_service.dart';
import 'package:mochi_player/core/infrastructure/database/sqlite_setup.dart';
import 'package:mochi_player/core/infrastructure/storage/storage_adapter_registry.dart';
import 'package:mochi_player/features/settings/infrastructure/app_settings_repository.dart';

import '../../../support/tmdb_fixture.dart';

void main() {
  for (final entry in {
    401: AppFailure.tmdbAuthentication,
    429: AppFailure.tmdbRateLimited,
    503: AppFailure.tmdbResponse,
  }.entries) {
    test('scan exposes ${entry.value}, keeps pending files, and can be retried', () async {
      final directory = await Directory.systemTemp.createTemp('mochi-tmdb-sync-');
      final database = DatabaseService.withDatabase(AppDatabase(NativeDatabase.memory(setup: configureSqlite)));
      await database.init();
      var status = entry.key;
      final tmdb = tmdbFixture(
        (request, handler) =>
            handler.resolve(Response<dynamic>(requestOptions: request, statusCode: status, data: {'results': []})),
      );
      final dependencies = ApplicationDependencies(
        database: database,
        tmdb: tmdb,
        storageRegistry: StorageAdapterRegistry.defaults(),
        settingsRepository: AppSettingsRepository(),
      );
      addTearDown(() async {
        await dependencies.mediaLibrary.shutdown();
        await dependencies.fileBrowser.shutdown();
        dependencies.storageSources.beginShutdown();
        await dependencies.storageSources.drain();
        dependencies.mediaLibrary.dispose();
        dependencies.fileBrowser.dispose();
        dependencies.settings.dispose();
        dependencies.trending.dispose();
        await database.close();
        await directory.delete(recursive: true);
      });
      await File('${directory.path}/Example.2020.mkv').writeAsString('fixture');
      await dependencies.storageSources.save(
        StorageSource(id: 'local', name: 'Local', type: StorageSourceType.local, endpoint: directory.path),
      );
      final summary = await dependencies.mediaLibrary.scanMediaSources();
      expect(summary!.metadataFailedCount, 1);
      expect(dependencies.mediaLibrary.error, entry.value);
      final file = (await database.getMediaFile('local', '/Example.2020.mkv'))!;
      expect(file.metadataMatchStatus, MetadataMatchStatus.pending);
      status = 200; // A successful empty result is now a genuine unmatched file.
      final retried = await dependencies.mediaLibrary.scanMediaSources();
      expect(retried!.metadataFailedCount, 1);
      expect(dependencies.mediaLibrary.error, isNull);
      expect((await database.getMediaFile('local', file.path))!.metadataMatchStatus, MetadataMatchStatus.unmatched);
    });
  }
}
