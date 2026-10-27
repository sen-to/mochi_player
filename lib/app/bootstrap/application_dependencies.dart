import 'package:mochi_player/core/infrastructure/database/database_service.dart';
import 'package:mochi_player/core/infrastructure/storage/storage_adapter_registry.dart';
import 'package:mochi_player/core/infrastructure/storage/storage_source_playback_resolver.dart';
import 'package:mochi_player/core/infrastructure/storage/storage_source_repository.dart';
import 'package:mochi_player/core/infrastructure/tmdb/tmdb_service.dart';
import 'package:mochi_player/features/home/application/trending_media_provider.dart';
import 'package:mochi_player/features/library/browser/file_browser_provider.dart';
import 'package:mochi_player/features/library/sync/library_sync_service.dart';
import 'package:mochi_player/features/library/media_library_provider.dart';
import 'package:mochi_player/features/library/metadata/metadata_matcher.dart';
import 'package:mochi_player/features/library/metadata/metadata_scraper.dart';
import 'package:mochi_player/features/library/sources/storage_sources_service.dart';
import 'package:mochi_player/features/library/sync/database_library_sync_repository.dart';
import 'package:mochi_player/features/library/metadata/database_metadata_repository.dart';
import 'package:mochi_player/features/library/catalog/library_repository.dart';
import 'package:mochi_player/features/library/sync/storage_library_source_scanner.dart';
import 'package:mochi_player/features/library/metadata/tmdb_metadata_source.dart';
import 'package:mochi_player/features/playback/infrastructure/database_playback_media_repository.dart';
import 'package:mochi_player/features/settings/application/app_settings_provider.dart';
import 'package:mochi_player/features/settings/infrastructure/app_settings_repository.dart';

/// Composition root: all application users receive the same owned services.
class ApplicationDependencies {
  ApplicationDependencies({
    required this.database,
    required TmdbService tmdb,
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
      onSourceRemoved: (id) {
        if (fileBrowser.activeSource?.id == id) fileBrowser.clearStorageSource();
      },
    );
    final repository = LibraryRepository(database);
    final metadataRepository = DatabaseMetadataRepository(database: database);
    final scraper = MetadataScraper(
      matchResolver: MetadataMatcher(
        source: TmdbMetadataSource(service: tmdb),
        repository: metadataRepository,
      ),
      repository: metadataRepository,
    );
    final sync = LibrarySyncService(
      repository: DatabaseLibrarySyncRepository(database: database),
      sourceScanner: StorageLibrarySourceScanner(repository: sourceRepository, registry: storageRegistry),
      metadataScraper: scraper,
    );
    mediaLibrary = MediaLibraryProvider(database: database, repository: repository, syncService: sync);
    settings = AppSettingsProvider(settingsRepository: settingsRepository, tmdbService: tmdb);
    trending = TrendingMediaProvider(tmdbService: tmdb);
    playbackRepository = DatabasePlaybackMediaRepository(database: database);
    playbackResolver = StorageSourcePlaybackResolver(repository: sourceRepository);
  }

  final DatabaseService database;
  late final FileBrowserProvider fileBrowser;
  late final StorageSourcesService storageSources;
  late final MediaLibraryProvider mediaLibrary;
  late final AppSettingsProvider settings;
  late final TrendingMediaProvider trending;
  late final DatabasePlaybackMediaRepository playbackRepository;
  late final StorageSourcePlaybackResolver playbackResolver;
}
