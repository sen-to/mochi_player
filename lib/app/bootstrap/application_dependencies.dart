// 【应用组装】集中选择实现、构造共享实例并连接跨功能回调。
// 业务通过构造参数接收依赖，资源作用域由启动入口决定。

import 'dart:async';

import 'package:mochi_player/core/data/database/app_database.dart';
import 'package:mochi_player/core/data/storage/database_storage_source_repository.dart';
import 'package:mochi_player/core/data/storage/storage_source_playback_resolver.dart';
import 'package:mochi_player/core/data/tmdb/tmdb_api.dart';
import 'package:mochi_player/core/domain/storage/storage_adapter_registry.dart';
import 'package:mochi_player/features/home/application/trending_media_provider.dart';
import 'package:mochi_player/features/home/data/tmdb_trending_media_source.dart';
import 'package:mochi_player/features/library/application/media_library_provider.dart';
import 'package:mochi_player/features/library/browser/application/file_browser_provider.dart';
import 'package:mochi_player/features/library/catalog/data/database_library_catalog_repository.dart';
import 'package:mochi_player/features/library/metadata/application/metadata_matcher.dart';
import 'package:mochi_player/features/library/metadata/application/metadata_scraper.dart';
import 'package:mochi_player/features/library/metadata/data/database_metadata_repository.dart';
import 'package:mochi_player/features/library/metadata/data/tmdb_metadata_source.dart';
import 'package:mochi_player/features/library/sources/application/storage_sources_service.dart';
import 'package:mochi_player/features/library/sync/application/library_sync_service.dart';
import 'package:mochi_player/features/library/sync/data/database_library_sync_repository.dart';
import 'package:mochi_player/features/library/sync/data/storage_library_source_scanner.dart';
import 'package:mochi_player/features/playback/data/database_playback_media_repository.dart';
import 'package:mochi_player/features/settings/application/app_settings_provider.dart';
import 'package:mochi_player/features/settings/application/app_settings_repository.dart';
import 'package:mochi_player/features/settings/data/tmdb_settings_runtime.dart';

/// 依赖组装根入口，应用使用者获得同一组有明确所有者的服务。
class ApplicationDependencies {
  ApplicationDependencies({
    required this.database,
    required TmdbApi tmdb,
    required StorageAdapterRegistry storageRegistry,
    required AppSettingsRepository settingsRepository,
  }) {
    final sourceRepository = DatabaseStorageSourceRepository(database: database);
    fileBrowser = FileBrowserProvider(
      storageAdapterRegistry: storageRegistry,
      readCredentials: sourceRepository.readCredentials,
    );
    storageSources = StorageSourcesService(
      repository: sourceRepository,
      registry: storageRegistry,
      onSourceChanged: fileBrowser.invalidateSource,
    );
    final repository = DatabaseLibraryCatalogRepository(database);
    final metadataRepository = DatabaseMetadataRepository(database: database);
    final scraper = MetadataScraper(
      matcher: MetadataMatcher(
        source: TmdbMetadataSource(api: tmdb),
        repository: metadataRepository,
      ),
      repository: metadataRepository,
    );
    final sync = LibrarySyncService(
      repository: DatabaseLibrarySyncRepository(database: database),
      sourceScanner: StorageLibrarySourceScanner(repository: sourceRepository, registry: storageRegistry),
      metadataScraper: scraper,
    );
    mediaLibrary = MediaLibraryProvider(repository: repository, syncService: sync);
    trending = TrendingMediaProvider(source: TmdbTrendingMediaSource(tmdb));
    settings = AppSettingsProvider(
      settingsRepository: settingsRepository,
      runtime: TmdbSettingsRuntime(tmdbApi: tmdb),
      onTmdbConfigurationChanged: () => unawaited(trending.fetch(refresh: true)),
    );
    playbackRepository = DatabasePlaybackMediaRepository(database: database);
    playbackResolver = StorageSourcePlaybackResolver(repository: sourceRepository);
  }

  final AppDatabase database;
  late final FileBrowserProvider fileBrowser;
  late final StorageSourcesService storageSources;
  late final MediaLibraryProvider mediaLibrary;
  late final AppSettingsProvider settings;
  late final TrendingMediaProvider trending;
  late final DatabasePlaybackMediaRepository playbackRepository;
  late final StorageSourcePlaybackResolver playbackResolver;
}
