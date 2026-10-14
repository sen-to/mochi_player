import 'package:drift/drift.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/infrastructure/database/json_converters.dart';

part 'app_database.g.dart';

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
  TextColumn get tvShowTmdbId => text().references(TVShows, #tmdbId, onDelete: KeyAction.cascade)();

  IntColumn get seasonNumber => integer()();

  TextColumn get title => text()();

  TextColumn get posterUrl => text().nullable()();

  TextColumn get overview => text().nullable()();

  IntColumn get numberOfEpisodes => integer().nullable()();

  @override
  Set<Column> get primaryKey => {tvShowTmdbId, seasonNumber};

  @override
  List<String> get customConstraints => ['CHECK (season_number >= 0)'];
}

@DataClassName('StorageSourceRow')
class StorageSources extends Table {
  TextColumn get sourceId => text()();

  TextColumn get name => text()();

  TextColumn get type => text()();

  TextColumn get endpoint => text()();

  TextColumn get rootPath => text()();

  BoolColumn get enabled => boolean()();

  TextColumn get username => text()();

  TextColumn get password => text()();

  @override
  Set<Column> get primaryKey => {sourceId};
}

@DriftDatabase(tables: [Movies, TVShows, Seasons, StorageSources], include: {'media_tables.drift'})
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: _initializeSchema,
    onUpgrade: (m, from, to) => _initializeSchema(m),
    beforeOpen: (_) async {
      await customStatement('PRAGMA busy_timeout = 5000');
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _initializeSchema(Migrator m) async {
    // Serialize first creation and development reset across independent openers.
    await customStatement('BEGIN IMMEDIATE');
    try {
      final version = (await customSelect('PRAGMA user_version').getSingle()).read<int>('user_version');
      if (version == 1) {
        // No released v1 data: drop the old development schema without copying.
        for (final name in ['media_files', 'episodes', 'seasons', 'movies', 't_v_shows', 'storage_sources']) {
          await m.deleteTable(name);
        }
      } else if (version != 0 && version != schemaVersion) {
        throw StateError('Unsupported database version: $version');
      }
      if (version != schemaVersion) {
        await m.createAll();
        await customStatement('PRAGMA user_version = $schemaVersion');
      }
      await customStatement('COMMIT');
    } catch (_) {
      await customStatement('ROLLBACK');
      rethrow;
    }
  }
}
