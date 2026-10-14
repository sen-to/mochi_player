import 'package:drift/drift.dart';
import 'package:mochi_player/core/domain/media/library_search_text.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/formatters/media_format.dart';
import 'package:mochi_player/core/infrastructure/database/app_database.dart';
import 'package:mochi_player/core/infrastructure/database/database_service.dart';
import 'package:mochi_player/features/library/application/media_card_view_data.dart';

/// SQL owns availability, ordering and paging. Only scoped projections leave the database.
class LibraryRepository {
  LibraryRepository(this._service);

  final DatabaseService _service;

  AppDatabase get _db => _service.database;

  Stream<int> watchFileCount() => _db
      .customSelect('SELECT COUNT(*) AS total FROM media_files', readsFrom: {_db.mediaFiles})
      .watchSingle()
      .map((row) => row.read<int>('total'));

  static const _titles = '''
    SELECT 'movie' AS kind, m.tmdb_id AS key, m.title, m.original_title,
      (SELECT MIN(added_at) FROM media_files f WHERE f.movie_tmdb_id=m.tmdb_id) AS added_at
    FROM movies m WHERE EXISTS (SELECT 1 FROM media_files f WHERE f.media_type='movie' AND f.movie_tmdb_id=m.tmdb_id)
    UNION ALL
    SELECT 'show', m.tmdb_id, m.title, m.original_title,
      (SELECT MIN(added_at) FROM media_files f WHERE f.tv_show_tmdb_id=m.tmdb_id)
    FROM t_v_shows m WHERE EXISTS (SELECT 1 FROM media_files f WHERE f.media_type='episode' AND f.tv_show_tmdb_id=m.tmdb_id)
  ''';

  /// Ranking matches the shared title matcher, including Unicode and punctuation.
  Stream<List<LibraryItem>> watchTitles({String? kind, String query = '', bool recent = false, int limit = 100}) {
    final normalized = normalizeLibrarySearchText(query);
    final sql = '''WITH titles AS ($_titles), ranked AS (
      SELECT *, MAX(
        CASE WHEN library_normalize(title)=?1 THEN 120 WHEN instr(library_normalize(title),?1)=1 THEN 100
          WHEN instr(library_normalize(title),?1)>0 THEN 80 ELSE 0 END,
        CASE WHEN library_normalize(original_title)=?1 THEN 110 WHEN instr(library_normalize(original_title),?1)=1 THEN 90
          WHEN instr(library_normalize(original_title),?1)>0 THEN 70 ELSE 0 END) AS score
      FROM titles)
      SELECT * FROM ranked WHERE (?1='' OR score>0) AND (?2='' OR kind=?2)
      ORDER BY ${recent ? 'added_at DESC,' : ''} ${normalized.isEmpty ? '' : 'score DESC,'} kind,key LIMIT ?3''';
    return _db
        .customSelect(
          sql,
          variables: [Variable(normalized), Variable(kind ?? ''), Variable(limit)],
          readsFrom: {_db.mediaFiles, _db.movies, _db.tVShows},
        )
        .watch()
        .asyncMap(_readTitles);
  }

  Future<List<LibraryItem>> _readTitles(List<QueryRow> rows) async {
    final items = <String, LibraryItem>{};
    // Fetch only the selected page in two sets, rather than a SELECT per title.
    for (final kind in ['movie', 'show']) {
      final ids = rows.where((row) => row.read<String>('kind') == kind).map((row) => row.read<String>('key')).toList();
      for (var offset = 0; offset < ids.length; offset += 400) {
        final batch = ids.skip(offset).take(400);
        final List<LibraryItem> values = kind == 'movie'
            ? await (_db.select(_db.movies)..where((t) => t.tmdbId.isIn(batch))).get()
            : await (_db.select(_db.tVShows)..where((t) => t.tmdbId.isIn(batch))).get();
        for (final item in values) {
          items['$kind:${item.tmdbId}'] = item;
        }
      }
    }
    return List.unmodifiable([
      for (final row in rows) ?items['${row.read<String>('kind')}:${row.read<String>('key')}'],
    ]);
  }

  Stream<LibraryItem?> watchHero() {
    final today = DateTime.now();
    final seed = today.year * 10000 + today.month * 100 + today.day;
    return _db
        .customSelect(
          '''WITH titles AS ($_titles)
      SELECT kind,key FROM titles ORDER BY kind,key LIMIT 1
      OFFSET (?1 % MAX((SELECT COUNT(*) FROM titles),1))''',
          variables: [Variable(seed)],
          readsFrom: {_db.mediaFiles, _db.movies, _db.tVShows},
        )
        .watch()
        .asyncMap(
          (rows) async =>
              rows.isEmpty ? null : _title(rows.single.read<String>('kind'), rows.single.read<String>('key')),
        );
  }

  Future<LibraryItem?> _title(String kind, String id) =>
      kind == 'movie' ? _service.getMovieByTmdbId(id) : _service.getTVShowByTmdbId(id);

  Stream<LibraryItem?> watchDetail(LibraryItem item) => _db
      .customSelect('SELECT 1', readsFrom: {_db.movies, _db.tVShows, _db.seasons, _db.episodes})
      .watchSingle()
      .asyncMap((_) async {
        if (item is Movie) return _service.getMovieByTmdbId(item.tmdbId);
        final show = await _service.getTVShowByTmdbId(item.tmdbId);
        if (show == null) return null;
        final seasons =
            await (_db.select(_db.seasons)
                  ..where((t) => t.tvShowTmdbId.equals(show.tmdbId))
                  ..orderBy([(t) => OrderingTerm.asc(t.seasonNumber)]))
                .get();
        final episodes =
            await (_db.select(_db.episodes)
                  ..where((t) => t.tvShowTmdbId.equals(show.tmdbId))
                  ..orderBy([(t) => OrderingTerm.asc(t.seasonNumber), (t) => OrderingTerm.asc(t.episodeNumber)]))
                .get();
        final bySeason = <int, List<Episode>>{};
        for (final episode in episodes) {
          (bySeason[episode.seasonNumber] ??= []).add(episode);
        }
        return show.withSeasons([
          for (final season in seasons) season.withEpisodes(bySeason[season.seasonNumber] ?? const []),
        ]);
      });

  Selectable<MediaFile> _versions(LibraryItem item) => _db.select(_db.mediaFiles)
    ..where((t) => item is Movie ? t.movieTmdbId.equals(item.tmdbId) : t.tvShowTmdbId.equals(item.tmdbId))
    ..orderBy([
      (t) => OrderingTerm.asc(t.parsedSeason),
      (t) => OrderingTerm.asc(t.parsedEpisode),
      (t) => OrderingTerm.asc(t.path),
    ]);

  Future<List<MediaFile>> getVersions(LibraryItem item) => _versions(item).get();

  Stream<List<MediaFile>> watchVersions(LibraryItem item) => _versions(item).watch();

  Future<MediaFile?> getEpisodeFile(String id) =>
      (_db.select(_db.mediaFiles)
            ..where((t) => t.episodeKey.equals(id))
            ..orderBy([(t) => OrderingTerm.asc(t.id)])
            ..limit(1))
          .getSingleOrNull();

  Future<List<MediaFile>> getPlaybackQueue(MediaFile file) async {
    if (file.mediaType != MediaType.episode) return [file];
    final files =
        await (_db.select(_db.mediaFiles)
              ..where(
                (t) =>
                    t.mediaType.equalsValue(MediaType.episode) &
                    (file.tvShowTmdbId != null
                        ? t.tvShowTmdbId.equals(file.tvShowTmdbId!)
                        : t.tvShowTmdbId.isNull() &
                              t.parsedTitle.lower().trim().equals(file.parsedTitle.toLowerCase().trim())),
              )
              ..orderBy([
                (t) => OrderingTerm.asc(t.parsedSeason),
                (t) => OrderingTerm.asc(t.parsedEpisode),
                (t) => OrderingTerm.asc(t.path),
              ]))
            .get();
    return files.any((f) => f.storageKey == file.storageKey) ? files : [file, ...files];
  }

  // Logical grouping is shared by favorites and continue watching.
  static const _group = '''CASE WHEN media_type='episode' THEN
    CASE WHEN tv_show_tmdb_id IS NOT NULL THEN 'tv:'||tv_show_tmdb_id
      WHEN trim(parsed_title)<>'' THEN 'tv-title:'||lower(trim(parsed_title))
      ELSE 'file:'||id END
    WHEN media_type='movie' AND movie_tmdb_id IS NOT NULL THEN 'movie:'||movie_tmdb_id
    ELSE 'file:'||id END''';

  Stream<List<MediaCardViewData>> watchFavorites({String query = '', int limit = 100}) {
    // Deduplicate favorited versions before ranking and LIMIT.
    final sql = '''WITH grouped AS (SELECT *, $_group AS group_key FROM media_files WHERE is_favorite=1),
      representatives AS (SELECT *,ROW_NUMBER() OVER (PARTITION BY group_key ORDER BY id) AS rank FROM grouped)
      SELECT r.*,MAX(
        CASE WHEN library_normalize(COALESCE(m.title,s.title,r.parsed_title))=?1 THEN 120
          WHEN instr(library_normalize(COALESCE(m.title,s.title,r.parsed_title)),?1)=1 THEN 100
          WHEN instr(library_normalize(COALESCE(m.title,s.title,r.parsed_title)),?1)>0 THEN 80 ELSE 0 END,
        CASE WHEN library_normalize(COALESCE(m.original_title,s.original_title,''))=?1 THEN 110
          WHEN instr(library_normalize(COALESCE(m.original_title,s.original_title,'')),?1)=1 THEN 90
          WHEN instr(library_normalize(COALESCE(m.original_title,s.original_title,'')),?1)>0 THEN 70 ELSE 0 END) AS score
      FROM representatives r
      LEFT JOIN movies m ON m.tmdb_id=r.movie_tmdb_id LEFT JOIN t_v_shows s ON s.tmdb_id=r.tv_show_tmdb_id
      WHERE r.rank=1 AND (?1='' OR instr(library_normalize(COALESCE(m.title,s.title,r.parsed_title)),?1)>0
        OR instr(library_normalize(COALESCE(m.original_title,s.original_title,'')),?1)>0)
      ORDER BY CASE WHEN ?1='' THEN 0 ELSE score END DESC,r.id LIMIT ?2''';
    return _db
        .customSelect(
          sql,
          variables: [Variable(normalizeLibrarySearchText(query)), Variable(limit)],
          readsFrom: {_db.mediaFiles, _db.movies, _db.tVShows},
        )
        .watch()
        .asyncMap((rows) async => [for (final row in rows) await _card(_db.mediaFiles.map(row.data))]);
  }

  Stream<List<MediaCardViewData>> watchContinueWatching({int limit = 100}) {
    // Select one physical target per title in SQL before LIMIT. Completed shows
    // with no next episode disappear without consuming a page slot.
    final sql = '''WITH grouped AS (SELECT *, $_group AS group_key FROM media_files),
      watched AS (SELECT *,ROW_NUMBER() OVER (PARTITION BY group_key ORDER BY last_watched_at DESC,
        COALESCE(parsed_season,999999),COALESCE(parsed_episode,999999),lower(path),id) AS rank
        FROM grouped WHERE media_type='episode' AND watch_status<>'notStarted' AND last_watched_at IS NOT NULL),
      episode_targets AS (SELECT last_watched_at AS activity,group_key,
        CASE WHEN watch_status='watching' THEN id ELSE (
          SELECT c.id FROM grouped c WHERE c.group_key=l.group_key AND c.watch_status<>'completed'
          AND (COALESCE(c.parsed_season,999999),COALESCE(c.parsed_episode,999999),lower(c.path)) >
              (COALESCE(l.parsed_season,999999),COALESCE(l.parsed_episode,999999),lower(l.path))
          AND NOT (c.episode_key IS NOT NULL AND l.episode_key IS NOT NULL AND c.episode_key=l.episode_key)
          AND NOT (c.parsed_season IS NOT NULL AND c.parsed_episode IS NOT NULL AND l.parsed_season IS NOT NULL AND l.parsed_episode IS NOT NULL
            AND c.parsed_season=l.parsed_season AND c.parsed_episode=l.parsed_episode)
          ORDER BY COALESCE(c.parsed_season,999999),COALESCE(c.parsed_episode,999999),lower(c.path),c.id LIMIT 1
        ) END AS target_id FROM watched l WHERE rank=1),
      other_watching AS (SELECT *,ROW_NUMBER() OVER (PARTITION BY group_key ORDER BY last_watched_at DESC,id) AS rank
        FROM grouped WHERE media_type<>'episode' AND watch_status='watching'),
      targets AS (SELECT activity,group_key,target_id FROM episode_targets
        UNION ALL SELECT last_watched_at,group_key,id FROM other_watching WHERE rank=1)
      SELECT g.* FROM targets t JOIN media_files g ON g.id=t.target_id
      ORDER BY COALESCE(t.activity,'1970-01-01T00:00:00.000Z') DESC,t.group_key LIMIT ?1''';
    return _db
        .customSelect(sql, variables: [Variable(limit)], readsFrom: {_db.mediaFiles, _db.movies, _db.tVShows})
        .watch()
        .asyncMap(
          (rows) async => [for (final row in rows) await _card(_db.mediaFiles.map(row.data), useBackdrop: true)],
        );
  }

  Future<MediaCardViewData> _card(MediaFile file, {bool useBackdrop = false}) async {
    final id = file.mediaType == MediaType.episode ? file.tvShowTmdbId : file.movieTmdbId;
    final item = id == null ? null : await _title(file.mediaType == MediaType.episode ? 'show' : 'movie', id);
    final subtitle = file.mediaType == MediaType.episode && useBackdrop
        ? MediaFormat.episodeCode(file)
        : item?.releaseYear?.toString();
    return MediaCardViewData(
      file: file,
      libraryItem: item,
      title: item?.title ?? file.parsedTitle,
      subtitle: subtitle,
      imageUrl: useBackdrop ? item?.backdropUrl : item?.posterUrl,
      rating: item?.rating ?? 0,
      playbackContextTitle: file.mediaType == MediaType.episode ? item?.title : null,
    );
  }

  Future<Set<String>> sourcePaths(String sourceId) async {
    final query = _db.selectOnly(_db.mediaFiles)
      ..addColumns([_db.mediaFiles.path])
      ..where(_db.mediaFiles.sourceId.equals(sourceId));
    return (await query.get()).map((row) => row.read(_db.mediaFiles.path)!).toSet();
  }

  Future<int> removeMissingFiles(String sourceId, Set<String> seen) async {
    final missing = (await sourcePaths(sourceId)).difference(seen).toList();
    var deleted = 0;
    await _db.transaction(() async {
      for (var i = 0; i < missing.length; i += 400) {
        deleted += await (_db.delete(
          _db.mediaFiles,
        )..where((t) => t.sourceId.equals(sourceId) & t.path.isIn(missing.skip(i).take(400)))).go();
      }
    });
    return deleted;
  }

  Future<List<MediaFile>> scrapeCandidates() async {
    final sql = '''SELECT * FROM media_files f WHERE
      (media_type='movie' AND (NOT EXISTS(SELECT 1 FROM movies m WHERE m.tmdb_id=f.movie_tmdb_id)
        OR (explicit_tmdb_id<>'' AND explicit_tmdb_id NOT GLOB '*[^0-9]*' AND explicit_tmdb_id<>COALESCE(movie_tmdb_id,''))))
      OR (media_type='episode' AND (NOT EXISTS(SELECT 1 FROM episodes e WHERE e.episode_key=f.episode_key)
        OR (explicit_tmdb_id<>'' AND explicit_tmdb_id NOT GLOB '*[^0-9]*' AND explicit_tmdb_id<>COALESCE(tv_show_tmdb_id,''))))''';
    return [for (final row in await _db.customSelect(sql).get()) _db.mediaFiles.map(row.data)];
  }
}
