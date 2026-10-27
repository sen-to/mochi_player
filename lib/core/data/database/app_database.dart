// 【数据库入口】统一 SQLite 表定义、连接、事务与公共读写操作。
// 应用创建并关闭唯一共享实例；复杂目录查询和功能契约由对应 Repository 实现。

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:mochi_player/core/data/database/mappers/episode_mapper.dart';
import 'package:mochi_player/core/data/database/mappers/media_file_mapper.dart';
import 'package:mochi_player/core/data/database/mappers/movie_mapper.dart';
import 'package:mochi_player/core/data/database/mappers/season_mapper.dart';
import 'package:mochi_player/core/data/database/mappers/tv_show_mapper.dart';
import 'package:mochi_player/core/data/database/sqlite_setup.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/domain/media/watch_progress_policy.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DataClassName('MovieDO')
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

  TextColumn get genres => text()();

  TextColumn get cast => text()();

  @override
  Set<Column> get primaryKey => {tmdbId};
}

@DataClassName('TVShowDO')
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

  TextColumn get genres => text()();

  TextColumn get cast => text()();

  TextColumn get status => text().nullable()();

  IntColumn get numberOfSeasons => integer().nullable()();

  IntColumn get numberOfEpisodes => integer().nullable()();

  @override
  Set<Column> get primaryKey => {tmdbId};
}

@DataClassName('SeasonDO')
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

@DataClassName('StorageSourceDO')
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

  /// 正式入口延迟建立后台连接，测试直接注入 SQLite 执行器。
  AppDatabase.open() : super(LazyDatabase(openConnection));

  Future<void>? _initializing;
  Future<void>? _closing;

  Future<void> init() => _initializing ??= _initializeConnection();

  Future<void> _initializeConnection() async {
    try {
      await customSelect('SELECT 1').get();
    } catch (_) {
      await close();
      rethrow;
    }
  }

  /// 多个收尾入口共享同一关闭操作；释放后的实例不再复用。
  @override
  Future<void> close() => _closing ??= super.close();

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
    // 跨独立连接串行执行首次创建与开发库重建。
    await customStatement('BEGIN IMMEDIATE');
    try {
      final version = (await customSelect('PRAGMA user_version').getSingle()).read<int>('user_version');
      if (version == 1) {
        // 尚无已发布的第一版用户数据，因此直接移除旧开发库结构，不复制数据。
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

  static Future<QueryExecutor> openConnection() async {
    final directory = await getApplicationDocumentsDirectory();
    return NativeDatabase.createInBackground(
      File(p.join(directory.path, 'mochi_player.sqlite')),
      setup: configureSqlite,
    );
  }

  Future<MediaFile?> getMediaFile(String sourceId, String path) async {
    final row = await (select(
      mediaFiles,
    )..where((t) => t.sourceId.equals(sourceId) & t.path.equals(path))).getSingleOrNull();
    return row == null ? null : MediaFileMapper.toDomain(row);
  }

  /// 扫描只更新文件属性，不覆盖元数据关联或用户状态；插入默认值用于新行，冲突更新仅修改属性。
  Future<void> saveScannedFiles(List<MediaFile> files) async {
    if (files.isEmpty) return;
    await batch((batch) {
      for (final file in files) {
        batch.update(
          mediaFiles,
          MediaFilesCompanion(
            movieTmdbId: Value(null),
            tvShowTmdbId: Value(null),
            episodeKey: Value(null),
            metadataMatchStatus: Value(MetadataMatchStatus.pending.name),
          ),
          where: (t) =>
              (t.sourceId.equals(file.sourceId) & t.path.equals(file.path)) &
              t.mediaType.equals(file.mediaType.name).not() &
              t.mediaType.equals(MediaType.unknown.name).not(),
        );
        final values = MediaFilesCompanion(
          sourceId: Value(file.sourceId),
          path: Value(file.path),
          fileName: Value(file.fileName),
          parsedTitle: Value(file.parsedTitle),
          parsedYear: Value(file.parsedYear),
          parsedSeason: Value(file.parsedSeason),
          parsedEpisode: Value(file.parsedEpisode),
          mediaType: Value(file.mediaType.name),
          explicitTmdbId: Value(file.explicitTmdbId),
          movieTmdbId: Value(file.movieTmdbId),
          tvShowTmdbId: Value(file.tvShowTmdbId),
          episodeKey: Value(file.episodeKey),
          metadataMatchStatus: Value(file.metadataMatchStatus.name),
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
          watchStatus: Value(file.watchStatus.name),
          lastWatchedAt: Value(file.lastWatchedAt),
          isFavorite: Value(file.isFavorite),
          addedAt: Value(file.addedAt),
        );
        // 显式列出可更新字段，确保以后新增的用户状态列不会被扫描覆盖。
        final attributes = MediaFilesCompanion(
          fileName: Value(file.fileName),
          parsedTitle: Value(file.parsedTitle),
          parsedYear: Value(file.parsedYear),
          parsedSeason: Value(file.parsedSeason),
          parsedEpisode: Value(file.parsedEpisode),
          mediaType: Value(file.mediaType.name),
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
          mediaFiles,
          values,
          onConflict: DoUpdate((_) => attributes, target: [mediaFiles.sourceId, mediaFiles.path]),
        );
      }
    });
  }

  Future<void> updateMediaMatches(List<MediaFile> files) async {
    if (files.isEmpty) return;
    await batch((batch) {
      for (final file in files) {
        batch.update(
          mediaFiles,
          MediaFilesCompanion(
            movieTmdbId: Value(file.movieTmdbId),
            tvShowTmdbId: Value(file.tvShowTmdbId),
            episodeKey: Value(file.episodeKey),
            metadataMatchStatus: Value(file.metadataMatchStatus.name),
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
    await (update(mediaFiles)..where((t) => (t.sourceId.equals(file.sourceId) & t.path.equals(file.path)))).write(
      MediaFilesCompanion(
        duration: Value(length),
        position: Value(normalized),
        lastWatchedAt: Value(DateTime.now().toUtc()),
        watchStatus: Value(status.name),
      ),
    );
  }

  Future<bool> setTitleFavorite(LibraryItem item, bool favorite) async =>
      await (update(mediaFiles)
            ..where((t) => item is Movie ? t.movieTmdbId.equals(item.tmdbId) : t.tvShowTmdbId.equals(item.tmdbId)))
          .write(MediaFilesCompanion(isFavorite: Value(favorite))) >
      0;

  Future<Movie?> getMovieByTmdbId(String id) async {
    final row = await (select(movies)..where((t) => t.tmdbId.equals(id))).getSingleOrNull();
    return row == null ? null : MovieMapper.toDomain(row);
  }

  Future<TVShow?> getTVShowByTmdbId(String id) async {
    final row = await (select(tVShows)..where((t) => t.tmdbId.equals(id))).getSingleOrNull();
    return row == null ? null : TVShowMapper.toDomain(row);
  }

  Future<void> saveMovieMetadata(Movie movie) async {
    await into(movies).insert(
      MovieMapper.toDO(movie).toCompanion(false),
      onConflict: DoUpdate((_) => MovieMapper.toDO(movie).toCompanion(false), target: [movies.tmdbId]),
    );
  }

  Future<void> saveTVShowMetadata(TVShow show) async {
    await into(tVShows).insert(
      TVShowMapper.toDO(show).toCompanion(false),
      onConflict: DoUpdate((_) => TVShowMapper.toDO(show).toCompanion(false), target: [tVShows.tmdbId]),
    );
  }

  Future<void> saveSeasonEpisodes(Season season, List<Episode> seasonEpisodes) => batch((batch) {
    batch.insert(
      seasons,
      SeasonMapper.toDO(season).toCompanion(false),
      onConflict: DoUpdate(
        (_) => SeasonMapper.toDO(season).toCompanion(false),
        target: [seasons.tvShowTmdbId, seasons.seasonNumber],
      ),
    );
    for (final episode in seasonEpisodes) {
      final values = EpisodeMapper.toDO(episode).toCompanion(false);
      batch.insert(episodes, values, onConflict: DoUpdate((_) => values, target: [episodes.episodeKey]));
    }
  });

  Future<List<StorageSourceDO>> getStorageSources() =>
      (select(storageSources)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();

  Future<StorageSourceDO?> getStorageSource(String id) =>
      (select(storageSources)..where((t) => t.sourceId.equals(id))).getSingleOrNull();

  Future<void> saveStorageSource(StorageSourceDO row) async {
    final values = row.toCompanion(false);
    await into(storageSources).insert(values, onConflict: DoUpdate((_) => values, target: [storageSources.sourceId]));
  }

  Future<bool> deleteStorageSource(String id) async =>
      await (delete(storageSources)..where((t) => t.sourceId.equals(id))).go() > 0;

  Future<int?> deleteStorageSourceAndMediaFiles(String id) => transaction(() async {
    if (await getStorageSource(id) == null) return null;
    final total = mediaFiles.id.count();
    final count =
        await (selectOnly(mediaFiles)
              ..addColumns([total])
              ..where(mediaFiles.sourceId.equals(id)))
            .getSingle();
    final removed = count.read(total)!;
    if (!await deleteStorageSource(id)) return null;
    return removed;
  });

  Future<void> clearLibrary() => transaction(() async {
    await delete(mediaFiles).go();
    await delete(movies).go();
    await delete(tVShows).go();
    await delete(seasons).go();
    await delete(episodes).go();
  });
}
