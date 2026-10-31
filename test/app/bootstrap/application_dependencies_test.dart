// 【行为测试】验证集中选择实现、构造共享实例并连接跨功能回调。
// 测试对象的职责边界：业务通过构造参数接收依赖，资源作用域由启动入口决定。

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/app/bootstrap/application_dependencies.dart';
import 'package:mochi_player/core/data/database/app_database.dart';
import 'package:mochi_player/core/data/database/sqlite_setup.dart';
import 'package:mochi_player/core/data/tmdb/tmdb_api.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/domain/storage/storage_adapter_registry.dart';
import 'package:mochi_player/features/settings/data/app_settings_repository_impl.dart';
import 'package:mochi_player/features/settings/domain/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/database_fixture.dart';

void main() {
  late AppDatabase database;
  late ApplicationDependencies dependencies;
  late TmdbApi tmdb;
  setUp(() async {
    SharedPreferences.setMockInitialValues({'tmdb_api_key': 'configured-key'});
    database = AppDatabase(NativeDatabase.memory(setup: configureSqlite));
    await database.init();
    tmdb = _TmdbApi();
    dependencies = ApplicationDependencies(
      database: database,
      tmdb: tmdb,
      storageRegistry: StorageAdapterRegistry([_StorageAdapter()]),
      settingsRepository: AppSettingsRepositoryImpl(),
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
    expect(TmdbApi().isConfigured, isFalse);
  });
  test('runtime settings refresh home collections through application wiring without a page', () async {
    await dependencies.settings.load();
    final service = tmdb as _TmdbApi;
    expect(service.collectionRequests, 0);
    const defaults = AppSettings();
    await dependencies.settings.saveSettings(
      tmdbApiKey: 'new-key',
      tmdbApiBaseUrl: defaults.tmdbApiBaseUrl,
      tmdbProxyUrl: defaults.tmdbProxyUrl,
      tmdbProxyEnabled: defaults.tmdbProxyEnabled,
      playbackCacheSizeMb: defaults.playbackCacheSizeMb,
      playbackReadaheadSeconds: defaults.playbackReadaheadSeconds,
      enableHardwareAcceleration: defaults.enableHardwareAcceleration,
      subtitleLanguagePriority: defaults.subtitleLanguagePriority,
      subtitleFontSize: defaults.subtitleFontSize,
      applyRuntime: true,
    );
    await Future<void>.delayed(Duration.zero);
    expect(service.collectionRequests, 3);
    expect(dependencies.trending.movies.single.title, 'Updated');
  });

  test('saving and deleting an active source clear the browser without an editor', () async {
    const source = StorageSource(id: 'local', name: 'Local', type: StorageSourceType.local, endpoint: '/media');
    expect(await dependencies.storageSources.save(source), false);
    await dependencies.fileBrowser.openStorageSource(source);
    expect(dependencies.fileBrowser.activeSource?.id, source.id);
    expect(await dependencies.storageSources.save(source), true);
    expect(dependencies.fileBrowser.hasSelectedStorageSource, false);
    await dependencies.fileBrowser.openStorageSource(source);
    expect(await dependencies.storageSources.deleteWithMedia(source.id), 0);
    expect(dependencies.fileBrowser.hasSelectedStorageSource, false);
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

class _TmdbApi extends TmdbApi {
  int collectionRequests = 0;
  Future<List<TrendingItem>> _collection() async {
    collectionRequests++;
    return const [TrendingItem(tmdbId: '1', title: 'Updated', isMovie: true)];
  }

  @override
  Future<List<TrendingItem>> fetchTrendingMovies({int limit = 3}) => _collection();
  @override
  Future<List<TrendingItem>> fetchTrendingTV({int limit = 3}) => _collection();
  @override
  Future<List<TrendingItem>> fetchTopRated({int limit = 3}) => _collection();
}

class _StorageAdapter implements StorageAdapter {
  @override
  StorageSourceType get type => StorageSourceType.local;
  @override
  Future<StorageConnection> connect(StorageSource source, StorageCredentials? credentials) async => _Connection(source);
}

class _Connection implements StorageConnection {
  _Connection(this.source);
  @override
  final StorageSource source;
  @override
  Future<List<StorageEntry>> readDirectory(String path) async => [];
  @override
  Future<void> close() async {}
}
