import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/app/bootstrap/application_dependencies.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/infrastructure/database/app_database.dart';
import 'package:mochi_player/core/infrastructure/database/database_service.dart';
import 'package:mochi_player/core/infrastructure/database/sqlite_setup.dart';
import 'package:mochi_player/core/infrastructure/storage/storage_adapter_registry.dart';
import 'package:mochi_player/core/infrastructure/tmdb/tmdb_service.dart';
import 'package:mochi_player/features/settings/infrastructure/app_settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../support/database_fixture.dart';

void main() {
  late DatabaseService database;
  late ApplicationDependencies dependencies;
  late TmdbService tmdb;
  setUp(() async {
    SharedPreferences.setMockInitialValues({'tmdb_api_key': 'configured-key'});
    database = DatabaseService.withDatabase(AppDatabase(NativeDatabase.memory(setup: configureSqlite)));
    await database.init();
    tmdb = TmdbService();
    dependencies = ApplicationDependencies(
      database: database,
      tmdb: tmdb,
      storageRegistry: StorageAdapterRegistry([]),
      settingsRepository: AppSettingsRepository(),
    );
  });
  tearDown(() async {
    dependencies.storageSources.beginShutdown();
    await dependencies.storageSources.drain();
    await dependencies.mediaLibrary.shutdown();
    await dependencies.fileBrowser.shutdown();
    dependencies.mediaLibrary.dispose();
    dependencies.fileBrowser.dispose();
    dependencies.settings.dispose();
    dependencies.trending.dispose();
    await database.close();
  });
  test('settings configure the same TMDB instance used by trending without global state', () async {
    expect(dependencies.trending.isConfigured, isFalse);
    await dependencies.settings.load();
    expect(tmdb.isConfigured, isTrue);
    expect(dependencies.trending.isConfigured, isTrue);
    expect(TmdbService().isConfigured, isFalse);
  });
  test('playback writes and favorites refresh the application query facade on the shared connection', () async {
    final file = MediaFile(
      id: 0,
      sourceId: 'nas',
      path: '/movie',
      fileName: 'movie',
      parsedTitle: 'Movie',
      mediaType: MediaType.movie,
      movieTmdbId: '1',
      addedAt: DateTime(2026),
    );
    await saveMediaFixture(database, [file]);
    const movie = Movie(tmdbId: '1', title: 'Movie');
    final updates = StreamIterator(dependencies.mediaLibrary.watchVersions(movie));
    try {
      expect(await updates.moveNext().timeout(const Duration(seconds: 2)), isTrue);
      await dependencies.playbackRepository.updateProgress(file, 42000, duration: 100000);
      expect(await updates.moveNext().timeout(const Duration(seconds: 2)), isTrue);
      expect(updates.current.single.position, 42000);
      await dependencies.mediaLibrary.setFavorite(movie, isFavorite: true);
      expect(await updates.moveNext().timeout(const Duration(seconds: 2)), isTrue);
      expect(updates.current.single.isFavorite, isTrue);
      expect(
        (await dependencies.playbackRepository.readMediaFile(sourceId: 'nas', path: '/movie'))!.isFavorite,
        isTrue,
      );
    } finally {
      await updates.cancel();
    }
  });
}
