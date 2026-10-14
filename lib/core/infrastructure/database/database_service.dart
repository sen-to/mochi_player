import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/domain/media/watch_progress_policy.dart';
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

  Future<MediaFile?> getMediaFile(String sourceId, String path) => (database.select(
    database.mediaFiles,
  )..where((t) => t.sourceId.equals(sourceId) & t.path.equals(path))).getSingleOrNull();

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
            episodeKey: Value(null),
            metadataMatchStatus: Value(MetadataMatchStatus.pending),
          ),
          where: (t) =>
              (t.sourceId.equals(file.sourceId) & t.path.equals(file.path)) &
              t.mediaType.equalsValue(file.mediaType).not() &
              t.mediaType.equalsValue(MediaType.unknown).not(),
        );
        final values = MediaFilesCompanion(
          sourceId: Value(file.sourceId),
          path: Value(file.path),
          fileName: Value(file.fileName),
          parsedTitle: Value(file.parsedTitle),
          parsedYear: Value(file.parsedYear),
          parsedSeason: Value(file.parsedSeason),
          parsedEpisode: Value(file.parsedEpisode),
          mediaType: Value(file.mediaType),
          explicitTmdbId: Value(file.explicitTmdbId),
          movieTmdbId: Value(file.movieTmdbId),
          tvShowTmdbId: Value(file.tvShowTmdbId),
          episodeKey: Value(file.episodeKey),
          metadataMatchStatus: Value(file.metadataMatchStatus),
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
          duration: Value(file.duration),
          position: Value(file.position),
          watchStatus: Value(file.watchStatus),
          lastWatchedAt: Value(file.lastWatchedAt),
          isFavorite: Value(file.isFavorite),
          addedAt: Value(file.addedAt),
        );
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
          values,
          onConflict: DoUpdate((_) => attributes, target: [database.mediaFiles.sourceId, database.mediaFiles.path]),
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
            episodeKey: Value(file.episodeKey),
            metadataMatchStatus: Value(file.metadataMatchStatus),
          ),
          where: (t) => (t.sourceId.equals(file.sourceId) & t.path.equals(file.path)),
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
    final status = WatchProgressPolicy.statusFor(normalized, length);
    await (database.update(
      database.mediaFiles,
    )..where((t) => (t.sourceId.equals(file.sourceId) & t.path.equals(file.path)))).write(
      MediaFilesCompanion(
        duration: Value(length),
        position: Value(normalized),
        lastWatchedAt: Value(DateTime.now().toUtc()),
        watchStatus: Value(status),
      ),
    );
  }

  Future<bool> setTitleFavorite(LibraryItem item, bool favorite) async =>
      await (database.update(database.mediaFiles)
            ..where((t) => item is Movie ? t.movieTmdbId.equals(item.tmdbId) : t.tvShowTmdbId.equals(item.tmdbId)))
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
      onConflict: DoUpdate(
        (_) => season.toInsertable(),
        target: [database.seasons.tvShowTmdbId, database.seasons.seasonNumber],
      ),
    );
    for (final episode in episodes) {
      final values = EpisodesCompanion(
        episodeKey: Value(episode.episodeKey),
        tvShowTmdbId: Value(episode.tvShowTmdbId),
        seasonNumber: Value(episode.seasonNumber),
        tmdbId: Value(episode.tmdbId),
        episodeNumber: Value(episode.episodeNumber),
        title: Value(episode.title),
        airDate: Value(episode.airDate),
        overview: Value(episode.overview),
        stillUrl: Value(episode.stillUrl),
        guestStars: Value(episode.guestStars),
      );
      batch.insert(
        database.episodes,
        values,
        onConflict: DoUpdate((_) => values, target: [database.episodes.episodeKey]),
      );
    }
  });

  Future<List<StorageSourceRow>> getStorageSources() =>
      (database.select(database.storageSources)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();

  Future<StorageSourceRow?> getStorageSource(String id) =>
      (database.select(database.storageSources)..where((t) => t.sourceId.equals(id))).getSingleOrNull();

  Future<void> saveStorageSource(StorageSourceRow row) async {
    final values = row.toCompanion(false);
    await database
        .into(database.storageSources)
        .insert(values, onConflict: DoUpdate((_) => values, target: [database.storageSources.sourceId]));
  }

  Future<bool> deleteStorageSource(String id) async =>
      await (database.delete(database.storageSources)..where((t) => t.sourceId.equals(id))).go() > 0;

  Future<int?> deleteStorageSourceAndMediaFiles(String id) => database.transaction(() async {
    if (await getStorageSource(id) == null) return null;
    final total = database.mediaFiles.id.count();
    final count =
        await (database.selectOnly(database.mediaFiles)
              ..addColumns([total])
              ..where(database.mediaFiles.sourceId.equals(id)))
            .getSingle();
    final removed = count.read(total)!;
    if (!await deleteStorageSource(id)) return null;
    return removed;
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
