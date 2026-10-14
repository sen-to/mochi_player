import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/infrastructure/database/app_database.dart';
import 'package:mochi_player/core/infrastructure/database/sqlite_setup.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// SQLite connection and write boundary. Read projections live in LibraryRepository.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  DatabaseService.withDatabase(AppDatabase database) : _database = database;

  AppDatabase? _database;
  Future<void>? _initializing;

  AppDatabase get database => _database ?? (throw StateError('Initialize the database before use'));

  Future<void> init() => _initializing ??= _initialize();

  Future<void> _initialize() async {
    try {
      _database ??= AppDatabase(await openConnection());
      await database.customSelect('SELECT 1').get();
    } catch (_) {
      final failed = _database;
      _database = null;
      _initializing = null;
      await failed?.close();
      rethrow;
    }
  }

  static Future<QueryExecutor> openConnection() async {
    final directory = await getApplicationDocumentsDirectory();
    return NativeDatabase.createInBackground(
      File(p.join(directory.path, 'mochi_player.sqlite')),
      setup: configureSqlite,
    );
  }

  Future<MediaFile?> getMediaFile(String sourceId, String path) =>
      (database.select(database.mediaFiles)..where((t) => t.storageKey.equals('$sourceId:$path'))).getSingleOrNull();

  /// Discovery owns file attributes, never provider associations or user state.
  /// Insert defaults initialize new rows; conflicts update attributes only.
  Future<void> saveScannedFiles(List<MediaFile> files) async {
    if (files.isEmpty) return;
    await database.batch((batch) {
      for (final file in files) {
        batch.update(
          database.mediaFiles,
          const MediaFilesCompanion(
            movieTmdbId: Value(null),
            tvShowTmdbId: Value(null),
            episodeTmdbId: Value(null),
            metadataMatchStatus: Value(MetadataMatchStatus.pending),
          ),
          where: (t) =>
              t.storageKey.equals(file.storageKey) &
              t.mediaType.equalsValue(file.mediaType).not() &
              t.mediaType.equalsValue(MediaType.unknown).not(),
        );
        final values = file.toInsertable().toColumns(false)..remove('id');
        // A positive field list makes adding a future user-state column safe.
        final attributes = MediaFilesCompanion(
          fileName: Value(file.fileName),
          parsedTitle: Value(file.parsedTitle),
          parsedYear: Value(file.parsedYear),
          parsedSeason: Value(file.parsedSeason),
          parsedEpisode: Value(file.parsedEpisode),
          mediaType: Value(file.mediaType),
          explicitTmdbId: Value(file.explicitTmdbId),
          size: Value(file.size),
          container: Value(file.container),
          width: Value(file.width),
          height: Value(file.height),
          videoCodec: Value(file.videoCodec),
          audioCodec: Value(file.audioCodec),
          audioChannels: Value(file.audioChannels),
          isHdr: Value(file.isHdr),
          hdrFormat: Value(file.hdrFormat),
          versionLabel: Value(file.versionLabel),
        );
        batch.insert(
          database.mediaFiles,
          RawValuesInsertable<MediaFile>(values),
          onConflict: DoUpdate((_) => attributes, target: [database.mediaFiles.storageKey]),
        );
      }
    });
  }

  Future<void> updateMediaMatches(List<MediaFile> files) async {
    if (files.isEmpty) return;
    await database.batch((batch) {
      for (final file in files) {
        batch.update(
          database.mediaFiles,
          MediaFilesCompanion(
            movieTmdbId: Value(file.movieTmdbId),
            tvShowTmdbId: Value(file.tvShowTmdbId),
            episodeTmdbId: Value(file.episodeTmdbId),
            metadataMatchStatus: Value(file.metadataMatchStatus),
          ),
          where: (t) => t.storageKey.equals(file.storageKey),
        );
      }
    });
  }

  Future<void> updateProgress(MediaFile file, int position, {int? duration}) async {
    final length = duration != null && duration > 0 ? duration : file.duration;
    final normalized = length > 0
        ? position.clamp(0, length).toInt()
        : position < 0
        ? 0
        : position;
    final status = normalized == 0
        ? WatchStatus.notStarted
        : length > 0 && normalized >= length * 0.95
        ? WatchStatus.completed
        : WatchStatus.watching;
    await (database.update(database.mediaFiles)..where((t) => t.storageKey.equals(file.storageKey))).write(
      MediaFilesCompanion(
        duration: Value(length),
        position: Value(normalized),
        lastWatchedAt: Value(DateTime.now().toUtc()),
        watchStatus: Value(status),
      ),
    );
  }

  Future<bool> setTitleFavorite(String tmdbId, bool favorite) async =>
      await (database.update(database.mediaFiles)
            ..where((t) => t.movieTmdbId.equals(tmdbId) | t.tvShowTmdbId.equals(tmdbId)))
          .write(MediaFilesCompanion(isFavorite: Value(favorite))) >
      0;

  Future<Movie?> getMovieByTmdbId(String id) =>
      (database.select(database.movies)..where((t) => t.tmdbId.equals(id))).getSingleOrNull();

  Future<TVShow?> getTVShowByTmdbId(String id) =>
      (database.select(database.tVShows)..where((t) => t.tmdbId.equals(id))).getSingleOrNull();

  Future<void> saveMovieMetadata(Movie movie) async {
    await database
        .into(database.movies)
        .insert(
          movie.toInsertable(),
          onConflict: DoUpdate((_) => movie.toInsertable(), target: [database.movies.tmdbId]),
        );
  }

  Future<void> saveTVShowMetadata(TVShow show) async {
    await database
        .into(database.tVShows)
        .insert(
          show.toInsertable(),
          onConflict: DoUpdate((_) => show.toInsertable(), target: [database.tVShows.tmdbId]),
        );
  }

  Future<void> saveSeasonEpisodes(Season season, List<Episode> episodes) => database.batch((batch) {
    batch.insert(
      database.seasons,
      season.toInsertable(),
      onConflict: DoUpdate((_) => season.toInsertable(), target: [database.seasons.seasonKey]),
    );
    for (final episode in episodes) {
      batch.insert(
        database.episodes,
        episode.toInsertable(),
        onConflict: DoUpdate((_) => episode.toInsertable(), target: [database.episodes.tmdbId]),
      );
    }
  });

  Future<List<StorageSourceRow>> getStorageSources() =>
      (database.select(database.storageSources)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();

  Future<StorageSourceRow?> getStorageSource(String id) =>
      (database.select(database.storageSources)..where((t) => t.sourceId.equals(id))).getSingleOrNull();

  Future<void> saveStorageSource(StorageSourceRow row) async {
    final values = row.toCompanion(false).copyWith(id: const Value.absent());
    await database
        .into(database.storageSources)
        .insert(values, onConflict: DoUpdate((_) => values, target: [database.storageSources.sourceId]));
  }

  Future<bool> deleteStorageSource(String id) async =>
      await (database.delete(database.storageSources)..where((t) => t.sourceId.equals(id))).go() > 0;

  Future<int?> deleteStorageSourceAndMediaFiles(String id) => database.transaction(() async {
    if (!await deleteStorageSource(id)) return null;
    return (database.delete(database.mediaFiles)..where((t) => t.sourceId.equals(id))).go();
  });

  Future<void> clearLibrary() => database.transaction(() async {
    await database.delete(database.mediaFiles).go();
    await database.delete(database.movies).go();
    await database.delete(database.tVShows).go();
    await database.delete(database.seasons).go();
    await database.delete(database.episodes).go();
  });

  Future<void> close() async {
    await _initializing;
    final db = _database;
    _database = null;
    _initializing = null;
    await db?.close();
  }
}
