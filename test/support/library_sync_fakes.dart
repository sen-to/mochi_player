import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/domain/media/season_metadata.dart';
import 'package:mochi_player/core/domain/storage/storage_source.dart';
import 'package:mochi_player/core/domain/storage/storage_source_type.dart';
import 'package:mochi_player/features/library/sync/library_source_scanner.dart';
import 'package:mochi_player/features/library/sync/library_sync_repository.dart';
import 'package:mochi_player/features/library/metadata/metadata_repository.dart';
import 'package:mochi_player/features/library/metadata/metadata_source.dart';

StorageSource librarySource(String id) =>
    StorageSource(id: id, name: id, type: StorageSourceType.local, endpoint: '/$id');

MediaFile libraryFile(String path, {String sourceId = 'local', int? season, int? episode}) => MediaFile(
  id: 0,
  sourceId: sourceId,
  path: path,
  fileName: path,
  parsedTitle: 'Example',
  mediaType: season == null ? MediaType.movie : MediaType.episode,
  parsedSeason: season,
  parsedEpisode: episode,
  addedAt: DateTime.utc(2026),
);

class FakeLibrarySourceScanner implements LibrarySourceScanner {
  List<StorageSource> available = [librarySource('local')];
  Future<List<StorageSource>> Function()? onSources;
  Future<LibrarySourceScan> Function(StorageSource)? onOpen;
  final opened = <String>[];
  final sessions = <String, FakeLibrarySourceScan>{};

  @override
  Future<List<StorageSource>> enabledSources() async => onSources == null ? available : await onSources!();

  @override
  Future<LibrarySourceScan> open(StorageSource source) async {
    opened.add(source.id);
    return onOpen == null ? sessions.putIfAbsent(source.id, FakeLibrarySourceScan.new) : await onOpen!(source);
  }
}

class FakeLibrarySourceScan implements LibrarySourceScan {
  Stream<MediaFile> Function()? onScan;
  Future<void> Function()? onClose;
  int closeCount = 0;
  int scanCount = 0;
  @override
  bool hadReadError = false;

  @override
  Stream<MediaFile> scan() {
    scanCount++;
    return onScan?.call() ?? const Stream.empty();
  }

  @override
  Future<void> close() async {
    closeCount++;
    await onClose?.call();
  }
}

class FakeLibrarySyncRepository implements LibrarySyncRepository {
  final paths = <String, Set<String>>{};
  final batches = <List<MediaFile>>[];
  final cleanedSources = <String>[];
  final seenPaths = <String, Set<String>>{};
  List<MediaFile> candidates = [];
  Future<void> Function(List<MediaFile>)? onSave;
  Future<Set<String>> Function(String)? onSourcePaths;
  int candidateReadCount = 0;

  @override
  Future<Set<String>> sourcePaths(String sourceId) async =>
      onSourcePaths == null ? paths[sourceId] ?? {} : await onSourcePaths!(sourceId);

  @override
  Future<void> saveScannedFiles(List<MediaFile> files) async {
    if (files.isEmpty) return;
    await onSave?.call(files);
    batches.add(List.of(files));
  }

  @override
  Future<int> removeMissingFiles(String sourceId, Set<String> seen) async {
    cleanedSources.add(sourceId);
    seenPaths[sourceId] = Set.of(seen);
    return (paths[sourceId] ?? {}).difference(seen).length;
  }

  @override
  Future<List<MediaFile>> scrapeCandidates() async {
    candidateReadCount++;
    return candidates;
  }
}

class FakeMetadataSource implements MetadataSource {
  @override
  bool isConfigured = true;
  final calls = <String>[];
  final movies = <String, Movie>{};
  final shows = <String, TVShow>{};
  final seasons = <int, SeasonMetadata>{};
  Future<Movie?> Function(String, int?)? onSearchMovie;
  Future<TVShow?> Function(String, int?)? onSearchTVShow;
  Future<SeasonMetadata?> Function(String, int)? onSeason;

  @override
  Future<Movie?> fetchMovieById(String id) async {
    calls.add('movie:$id');
    return movies[id];
  }

  @override
  Future<TVShow?> fetchTVShowById(String id) async {
    calls.add('show:$id');
    return shows[id];
  }

  @override
  Future<Movie?> searchMovie(String title, {int? year}) async {
    calls.add('searchMovie:$title:$year');
    return await onSearchMovie?.call(title, year);
  }

  @override
  Future<TVShow?> searchTVShow(String title, {int? year}) async {
    calls.add('searchShow:$title:$year');
    return await onSearchTVShow?.call(title, year);
  }

  @override
  Future<SeasonMetadata?> fetchSeason(String showId, int seasonNumber) async {
    calls.add('season:$showId:$seasonNumber');
    return onSeason == null ? seasons[seasonNumber] : await onSeason!(showId, seasonNumber);
  }
}

class FakeMetadataRepository implements MetadataRepository {
  final movies = <String, Movie>{};
  final shows = <String, TVShow>{};
  final importedMovies = <MediaFile>[];
  final importedEpisodes = <String>[];
  final unmatched = <MediaFile>[];
  Future<void> Function(SeasonMetadata)? onImportSeason;
  Future<void> Function(List<MediaFile>)? onMarkUnmatched;

  @override
  Future<Movie?> findMovie(String id) async => movies[id];
  @override
  Future<TVShow?> findTVShow(String id) async => shows[id];

  @override
  Future<bool> importMovie(Movie movie, MediaFile file) async {
    importedMovies.add(file);
    final isNew = !movies.containsKey(movie.tmdbId);
    movies[movie.tmdbId] = movie;
    return isNew;
  }

  @override
  Future<bool> importTVShow(TVShow show) async {
    final isNew = !shows.containsKey(show.tmdbId);
    shows[show.tmdbId] = show;
    return isNew;
  }

  @override
  Future<Set<String>> importSeasonEpisodes(SeasonMetadata metadata, String showId, List<MediaFile> files) async {
    await onImportSeason?.call(metadata);
    final keys = files
        .where((file) => metadata.episodes.any((episode) => episode.episodeNumber == file.parsedEpisode))
        .map((file) => file.storageKey)
        .toSet();
    importedEpisodes.addAll(keys);
    return keys;
  }

  @override
  Future<void> markUnmatched(List<MediaFile> files) async {
    await onMarkUnmatched?.call(files);
    unmatched.addAll(files);
  }
}
