// 【数据访问】用 SQL 完成目录筛选、排序、分页及卡片元数据批量投影。
// 分页展示查询与全库推荐输入通过订阅发布，不处理弹窗或页面状态。

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:mochi_player/core/data/database/app_database.dart';
import 'package:mochi_player/core/data/database/mappers/episode_mapper.dart';
import 'package:mochi_player/core/data/database/mappers/media_file_mapper.dart';
import 'package:mochi_player/core/data/database/mappers/movie_mapper.dart';
import 'package:mochi_player/core/data/database/mappers/season_mapper.dart';
import 'package:mochi_player/core/data/database/mappers/tv_show_mapper.dart';
import 'package:mochi_player/core/domain/media/library_search_text.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/features/library/catalog/application/library_catalog_repository.dart';
import 'package:mochi_player/features/library/catalog/application/media_card_mapper.dart';
import 'package:mochi_player/features/library/catalog/application/media_card_vo.dart';
import 'package:mochi_player/features/library/catalog/data/library_recommendation_mapper.dart';
import 'package:mochi_player/features/library/catalog/domain/library_recommendation_candidate.dart';

import 'package:mochi_player/features/library/catalog/domain/library_title_filter.dart';

/// SQL 负责可用性、聚合与分页；推荐输入覆盖全库，普通展示只读取当前页。
class LibraryCatalogRepositoryImpl implements LibraryCatalogRepository {
  LibraryCatalogRepositoryImpl({required AppDatabase database}) : _database = database;

  final AppDatabase _database;

  @override
  Future<void> initialize() => _database.init();

  @override
  Future<bool> setFavorite(LibraryItem item, {required bool isFavorite}) =>
      _database.setTitleFavorite(item, isFavorite);

  @override
  Future<void> clearLibrary() => _database.clearLibrary();

  @override
  Stream<int> watchFileCount() => _database
      .customSelect('SELECT COUNT(*) AS total FROM media_files', readsFrom: {_database.mediaFiles})
      .watchSingle()
      .map((row) => row.read<int>('total'));

  static const _titles = '''
    SELECT 'movie' AS kind, m.tmdb_id AS key, m.title, m.original_title, m.genres, m.release_year, m.rating,
      (SELECT MIN(added_at) FROM media_files f WHERE f.movie_tmdb_id=m.tmdb_id) AS added_at
    FROM movies m WHERE EXISTS (SELECT 1 FROM media_files f WHERE f.media_type='movie' AND f.movie_tmdb_id=m.tmdb_id)
    UNION ALL
    SELECT 'show', m.tmdb_id, m.title, m.original_title, m.genres, m.release_year, m.rating,
      (SELECT MIN(added_at) FROM media_files f WHERE f.tv_show_tmdb_id=m.tmdb_id)
    FROM t_v_shows m WHERE EXISTS (SELECT 1 FROM media_files f WHERE f.media_type='episode' AND f.tv_show_tmdb_id=m.tmdb_id)
  ''';

  /// 排序与共享标题规则一致，包括 Unicode 和标点处理。
  @override
  Stream<List<LibraryItem>> watchTitles({
    LibraryTitleKind? kind,
    String query = '',
    bool recent = false,
    LibraryTitleFilter filter = const LibraryTitleFilter(),
    LibraryTitleSort? sort,
    int limit = 100,
  }) {
    final normalized = normalizeLibrarySearchText(query);
    final variables = <Variable>[Variable(normalized), Variable(_titleKind(kind)), Variable(limit)];
    final filterSql = _titleFilterSql(filter, variables);
    final order = switch (sort) {
      LibraryTitleSort.latestAdded => 'added_at DESC,',
      LibraryTitleSort.releaseYear => 'release_year DESC,',
      LibraryTitleSort.rating => 'rating DESC,',
      LibraryTitleSort.title => 'library_normalize(title),',
      null => recent ? 'added_at DESC,' : '',
    };
    final sql =
        '''WITH titles AS ($_titles), ranked AS (
      SELECT *, MAX(
        CASE WHEN library_normalize(title)=?1 THEN 120 WHEN instr(library_normalize(title),?1)=1 THEN 100
          WHEN instr(library_normalize(title),?1)>0 THEN 80 ELSE 0 END,
        CASE WHEN library_normalize(original_title)=?1 THEN 110 WHEN instr(library_normalize(original_title),?1)=1 THEN 90
          WHEN instr(library_normalize(original_title),?1)>0 THEN 70 ELSE 0 END) AS score
      FROM titles)
      SELECT * FROM ranked catalog WHERE (?1='' OR score>0) AND (?2='' OR kind=?2) $filterSql
      ORDER BY $order ${normalized.isEmpty ? '' : 'score DESC,'} kind,key LIMIT ?3''';
    return _database
        .customSelect(sql, variables: variables, readsFrom: {_database.mediaFiles, _database.movies, _database.tVShows})
        .watch()
        .asyncMap(_readTitles);
  }

  @override
  Stream<LibraryTitleCatalogSummary> watchTitleCatalogSummary(LibraryTitleKind kind, LibraryTitleFilter filter) {
    final variables = <Variable>[Variable(_titleKind(kind))];
    final filterSql = _titleFilterSql(filter, variables);
    return _database
        .customSelect(
          '''WITH titles AS ($_titles), category AS (SELECT * FROM titles WHERE kind=?1)
      SELECT (SELECT COUNT(*) FROM category catalog WHERE 1=1 $filterSql) AS count,
        (SELECT json_group_array(DISTINCT g.value) FROM category, json_each(${_genreArray('category.genres')}) g
          WHERE g.type='text' AND trim(g.value)<>'') AS genres,
        (SELECT json_group_array(DISTINCT (release_year/10)*10) FROM category WHERE release_year>0) AS decades''',
          variables: variables,
          readsFrom: {_database.mediaFiles, _database.movies, _database.tVShows},
        )
        .watchSingle()
        .map(
          (row) => (
            count: row.read<int>('count'),
            genres: (jsonDecode(row.read<String>('genres')) as List).cast<String>()..sort(),
            decades: (jsonDecode(row.read<String>('decades')) as List).cast<int>()..sort((a, b) => b.compareTo(a)),
          ),
        );
  }

  static String _titleKind(LibraryTitleKind? kind) => switch (kind) {
    LibraryTitleKind.movie => 'movie',
    LibraryTitleKind.tvShow => 'show',
    null => '',
  };

  static String _genreArray(String column) => "CASE WHEN json_valid($column) THEN $column ELSE '[]' END";

  static String _titleFilterSql(LibraryTitleFilter filter, List<Variable> variables) {
    String bind<T extends Object>(T value) {
      variables.add(Variable<T>(value));
      return '?${variables.length}';
    }

    final sql = StringBuffer();
    if (filter.genres.isNotEmpty) {
      final genres = bind(jsonEncode(filter.genres.toList()));
      sql.write(""" AND EXISTS (SELECT 1 FROM json_each(${_genreArray('catalog.genres')}) g
        WHERE g.type='text' AND g.value IN (SELECT value FROM json_each($genres)))""");
    }
    if (filter.decade case final decade?) {
      sql.write(' AND release_year BETWEEN ${bind(decade)} AND ${bind(decade + 9)}');
    }
    return sql.toString();
  }

  Future<List<LibraryItem>> _readTitles(List<QueryRow> rows) async {
    final items = await _loadTitles(
      movieIds: rows.where((row) => row.read<String>('kind') == 'movie').map((row) => row.read<String>('key')),
      showIds: rows.where((row) => row.read<String>('kind') == 'show').map((row) => row.read<String>('key')),
    );
    return List.unmodifiable([
      for (final row in rows) ?items['${row.read<String>('kind')}:${row.read<String>('key')}'],
    ]);
  }

  /// 只加载当前页的元数据，并按类型及 ID 去重。
  Future<Map<String, LibraryItem>> _loadTitles({
    required Iterable<String> movieIds,
    required Iterable<String> showIds,
  }) async {
    final items = <String, LibraryItem>{};
    final idsByKind = {'movie': movieIds.toSet().toList(), 'show': showIds.toSet().toList()};
    for (final entry in idsByKind.entries) {
      final ids = entry.value;
      // 扩展结果数量时限制每批 SQLite 参数规模。
      for (var offset = 0; offset < ids.length; offset += 400) {
        final batch = ids.skip(offset).take(400);
        final List<LibraryItem> values = entry.key == 'movie'
            ? (await (_database.select(
                _database.movies,
              )..where((t) => t.tmdbId.isIn(batch))).get()).map(MovieMapper.toDomain).toList()
            : (await (_database.select(
                _database.tVShows,
              )..where((t) => t.tmdbId.isIn(batch))).get()).map(TVShowMapper.toDomain).toList();
        for (final item in values) {
          items['${entry.key}:${item.tmdbId}'] = item;
        }
      }
    }
    return items;
  }

  @override
  Stream<List<LibraryRecommendationCandidate>> watchRecommendationCandidates() => _database
      .customSelect(
        """WITH linked AS (
          SELECT 'movie' AS kind,movie_tmdb_id AS key,is_favorite,watch_status,added_at,last_watched_at
          FROM media_files WHERE media_type='movie' AND movie_tmdb_id IS NOT NULL
          UNION ALL
          SELECT 'show',tv_show_tmdb_id,is_favorite,watch_status,added_at,last_watched_at
          FROM media_files WHERE media_type='episode' AND tv_show_tmdb_id IS NOT NULL)
        SELECT kind,key,MAX(is_favorite) AS favorite,MAX(watch_status<>'notStarted') AS started,
          MAX(watch_status='completed') AS completed,MIN(added_at) AS added_at,
          MAX(last_watched_at) AS watched_at FROM linked GROUP BY kind,key ORDER BY kind,key""",
        readsFrom: {_database.mediaFiles, _database.movies, _database.tVShows},
      )
      .watch()
      .asyncMap((rows) async {
        final items = await _loadTitles(
          movieIds: rows.where((row) => row.read<String>('kind') == 'movie').map((row) => row.read<String>('key')),
          showIds: rows.where((row) => row.read<String>('kind') == 'show').map((row) => row.read<String>('key')),
        );
        return List.unmodifiable([
          for (final row in rows)
            if (items['${row.read<String>('kind')}:${row.read<String>('key')}'] case final item?)
              LibraryRecommendationMapper.fromRow(row, item),
        ]);
      });

  @override
  Stream<LibraryItem?> watchDetail(LibraryItem item) => _database
      .customSelect('SELECT 1', readsFrom: {_database.movies, _database.tVShows, _database.seasons, _database.episodes})
      .watchSingle()
      .asyncMap((_) async {
        if (item is Movie) return _database.getMovieByTmdbId(item.tmdbId);
        final show = await _database.getTVShowByTmdbId(item.tmdbId);
        if (show == null) return null;
        final seasons =
            await (_database.select(_database.seasons)
                  ..where((t) => t.tvShowTmdbId.equals(show.tmdbId))
                  ..orderBy([(t) => OrderingTerm.asc(t.seasonNumber)]))
                .get();
        final episodes =
            await (_database.select(_database.episodes)
                  ..where((t) => t.tvShowTmdbId.equals(show.tmdbId))
                  ..orderBy([(t) => OrderingTerm.asc(t.seasonNumber), (t) => OrderingTerm.asc(t.episodeNumber)]))
                .get();
        final bySeason = <int, List<Episode>>{};
        for (final episode in episodes.map(EpisodeMapper.toDomain)) {
          (bySeason[episode.seasonNumber] ??= []).add(episode);
        }
        return show.withSeasons([
          for (final season in seasons.map(SeasonMapper.toDomain))
            season.withEpisodes(bySeason[season.seasonNumber] ?? const []),
        ]);
      });

  Selectable<MediaFileDO> _versions(LibraryItem item) => _database.select(_database.mediaFiles)
    ..where((t) => item is Movie ? t.movieTmdbId.equals(item.tmdbId) : t.tvShowTmdbId.equals(item.tmdbId))
    ..orderBy([
      (t) => OrderingTerm.asc(t.parsedSeason),
      (t) => OrderingTerm.asc(t.parsedEpisode),
      (t) => OrderingTerm.asc(t.path),
    ]);

  @override
  Future<List<MediaFile>> getVersions(LibraryItem item) async =>
      (await _versions(item).get()).map(MediaFileMapper.toDomain).toList(growable: false);

  @override
  Stream<List<MediaFile>> watchVersions(LibraryItem item) =>
      _versions(item).watch().map((rows) => rows.map(MediaFileMapper.toDomain).toList(growable: false));

  @override
  Future<MediaFile?> getEpisodeFile(String episodeKey) async {
    final row =
        (await (_database.select(_database.mediaFiles)
              ..where((t) => t.episodeKey.equals(episodeKey))
              ..orderBy([(t) => OrderingTerm.asc(t.id)])
              ..limit(1))
            .getSingleOrNull());
    return row == null ? null : MediaFileMapper.toDomain(row);
  }

  @override
  Future<List<MediaFile>> getPlaybackQueue(MediaFile file) async {
    if (file.mediaType != MediaType.episode) return [file];
    final files =
        await (_database.select(_database.mediaFiles)
              ..where(
                (t) =>
                    t.mediaType.equals(MediaType.episode.name) &
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
    final mediaFiles = files.map(MediaFileMapper.toDomain).toList(growable: false);
    return mediaFiles.any((f) => f.storageKey == file.storageKey) ? mediaFiles : [file, ...mediaFiles];
  }

  // 收藏和续播共用逻辑标题分组。
  static const _group = '''CASE WHEN media_type='episode' THEN
    CASE WHEN tv_show_tmdb_id IS NOT NULL THEN 'tv:'||tv_show_tmdb_id
      WHEN trim(parsed_title)<>'' THEN 'tv-title:'||lower(trim(parsed_title))
      ELSE 'file:'||id END
    WHEN media_type='movie' AND movie_tmdb_id IS NOT NULL THEN 'movie:'||movie_tmdb_id
    ELSE 'file:'||id END''';

  @override
  Stream<List<MediaCardVO>> watchFavorites({String query = '', int limit = 100}) {
    // 先去重收藏的多个版本，再执行排序与 LIMIT。
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
    return _database
        .customSelect(
          sql,
          variables: [Variable(normalizeLibrarySearchText(query)), Variable(limit)],
          readsFrom: {_database.mediaFiles, _database.movies, _database.tVShows},
        )
        .watch()
        .asyncMap(_readCards);
  }

  @override
  Stream<List<MediaCardVO>> watchContinueWatching({int limit = 100}) {
    // 先在 SQL 中为每个标题选定一个物理文件，再执行 LIMIT；没有下一集的已完成剧集不占用分页名额。
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
    return _database
        .customSelect(
          sql,
          variables: [Variable(limit)],
          readsFrom: {_database.mediaFiles, _database.movies, _database.tVShows},
        )
        .watch()
        .asyncMap((rows) => _readCards(rows, useBackdrop: true));
  }

  Future<List<MediaCardVO>> _readCards(List<QueryRow> rows, {bool useBackdrop = false}) async {
    final files = rows
        .map((row) => MediaFileMapper.toDomain(_database.mediaFiles.map(row.data)))
        .toList(growable: false);
    final items = await _loadTitles(
      movieIds: files
          .where((file) => file.mediaType != MediaType.episode)
          .map((file) => file.movieTmdbId)
          .whereType<String>(),
      showIds: files
          .where((file) => file.mediaType == MediaType.episode)
          .map((file) => file.tvShowTmdbId)
          .whereType<String>(),
    );
    // 保持 SQL 排序，字典映射不能引入逐卡片读取。
    return List.unmodifiable([for (final file in files) _card(file, items, useBackdrop: useBackdrop)]);
  }

  MediaCardVO _card(MediaFile file, Map<String, LibraryItem> items, {bool useBackdrop = false}) {
    final isEpisode = file.mediaType == MediaType.episode;
    final id = isEpisode ? file.tvShowTmdbId : file.movieTmdbId;
    final item = id == null ? null : items['${isEpisode ? 'show' : 'movie'}:$id'];
    return MediaCardMapper.toVO(file, item, useBackdrop: useBackdrop);
  }
}
