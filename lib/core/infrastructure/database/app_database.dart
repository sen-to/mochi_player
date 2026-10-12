import 'package:drift/drift.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/infrastructure/database/json_converters.dart';

part 'app_database.g.dart';

@UseRowClass(MediaFile, generateInsertable: true)
@TableIndex(name: 'media_files_source_id_idx', columns: {#sourceId})
@TableIndex(name: 'media_files_explicit_tmdb_id_idx', columns: {#explicitTmdbId})
@TableIndex(name: 'media_files_movie_tmdb_id_idx', columns: {#movieTmdbId})
@TableIndex(name: 'media_files_tv_show_tmdb_id_idx', columns: {#tvShowTmdbId})
@TableIndex(name: 'media_files_episode_tmdb_id_idx', columns: {#episodeTmdbId})
@TableIndex(name: 'media_files_watch_status_idx', columns: {#watchStatus})
@TableIndex(name: 'media_files_last_watched_at_idx', columns: {#lastWatchedAt})
@TableIndex(name: 'media_files_is_favorite_idx', columns: {#isFavorite})
@TableIndex(name: 'media_files_added_at_idx', columns: {#addedAt})
class MediaFiles extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get sourceId => text()();

  TextColumn get storageKey => text().unique()();

  TextColumn get path => text()();

  TextColumn get fileName => text()();

  TextColumn get parsedTitle => text()();

  IntColumn get parsedYear => integer().nullable()();

  IntColumn get parsedSeason => integer().nullable()();

  IntColumn get parsedEpisode => integer().nullable()();

  TextColumn get mediaType => textEnum<MediaType>()();

  TextColumn get explicitTmdbId => text().nullable()();

  TextColumn get movieTmdbId => text().nullable()();

  TextColumn get tvShowTmdbId => text().nullable()();

  TextColumn get episodeTmdbId => text().nullable()();

  TextColumn get metadataMatchStatus => textEnum<MetadataMatchStatus>()();

  IntColumn get size => integer()();

  TextColumn get container => text().nullable()();

  IntColumn get width => integer().nullable()();

  IntColumn get height => integer().nullable()();

  TextColumn get videoCodec => text().nullable()();

  TextColumn get audioCodec => text().nullable()();

  TextColumn get audioChannels => text().nullable()();

  BoolColumn get isHdr => boolean()();

  TextColumn get hdrFormat => text().nullable()();

  TextColumn get versionLabel => text().nullable()();

  IntColumn get duration => integer()();

  IntColumn get position => integer()();

  TextColumn get watchStatus => textEnum<WatchStatus>()();

  DateTimeColumn get lastWatchedAt => dateTime().nullable()();

  BoolColumn get isFavorite => boolean()();

  DateTimeColumn get addedAt => dateTime()();
}

@UseRowClass(Movie, generateInsertable: true)
class Movies extends Table {
  TextColumn get tmdbId => text()();

  TextColumn get title => text()();

  TextColumn get originalTitle => text().nullable()();

  IntColumn get releaseYear => integer().nullable()();

  DateTimeColumn get releaseDate => dateTime().nullable()();

  TextColumn get posterUrl => text().nullable()();

  TextColumn get backdropUrl => text().nullable()();

  TextColumn get logoUrl => text().nullable()();

  TextColumn get overview => text().nullable()();

  TextColumn get certification => text().nullable()();

  RealColumn get rating => real()();

  TextColumn get genres => text().map(const StringListConverter())();

  TextColumn get cast => text().map(const ArtistListConverter())();

  @override
  Set<Column> get primaryKey => {tmdbId};
}

@UseRowClass(TVShow, generateInsertable: true)
class TVShows extends Table {
  TextColumn get tmdbId => text()();

  TextColumn get title => text()();

  TextColumn get originalTitle => text().nullable()();

  IntColumn get releaseYear => integer().nullable()();

  DateTimeColumn get firstAirDate => dateTime().nullable()();

  TextColumn get posterUrl => text().nullable()();

  TextColumn get backdropUrl => text().nullable()();

  TextColumn get logoUrl => text().nullable()();

  TextColumn get overview => text().nullable()();

  TextColumn get certification => text().nullable()();

  RealColumn get rating => real()();

  TextColumn get genres => text().map(const StringListConverter())();

  TextColumn get cast => text().map(const ArtistListConverter())();

  TextColumn get status => text().nullable()();

  IntColumn get numberOfSeasons => integer().nullable()();

  IntColumn get numberOfEpisodes => integer().nullable()();

  @override
  Set<Column> get primaryKey => {tmdbId};
}

@UseRowClass(Season, generateInsertable: true)
class Seasons extends Table {
  TextColumn get seasonKey => text()();

  IntColumn get seasonNumber => integer()();

  TextColumn get title => text()();

  TextColumn get posterUrl => text().nullable()();

  TextColumn get overview => text().nullable()();

  IntColumn get numberOfEpisodes => integer().nullable()();

  @override
  Set<Column> get primaryKey => {seasonKey};
}

@UseRowClass(Episode, generateInsertable: true)
class Episodes extends Table {
  TextColumn get tmdbId => text()();

  IntColumn get episodeNumber => integer()();

  TextColumn get title => text()();

  DateTimeColumn get airDate => dateTime().nullable()();

  TextColumn get overview => text().nullable()();

  TextColumn get stillUrl => text().nullable()();

  TextColumn get guestStars => text().map(const ArtistListConverter())();

  @override
  Set<Column> get primaryKey => {tmdbId};
}

@DataClassName('StorageSourceRow')
class StorageSources extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get sourceId => text().unique()();

  TextColumn get name => text()();

  TextColumn get type => text()();

  TextColumn get endpoint => text()();

  TextColumn get rootPath => text()();

  BoolColumn get enabled => boolean()();

  TextColumn get username => text()();

  TextColumn get password => text()();
}

@DriftDatabase(tables: [MediaFiles, Movies, TVShows, Seasons, Episodes, StorageSources])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      // Other engines can also have observed user_version=0 before this lock.
      // Recheck after acquiring it and publish the schema atomically.
      await customStatement('BEGIN IMMEDIATE');
      try {
        final version = (await customSelect('PRAGMA user_version').getSingle()).read<int>('user_version');
        if (version == 0) {
          await m.createAll();
          await customStatement('PRAGMA user_version = $schemaVersion');
        }
        await customStatement('COMMIT');
      } catch (_) {
        await customStatement('ROLLBACK');
        rethrow;
      }
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA busy_timeout = 5000');
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
