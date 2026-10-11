// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MediaFilesTable extends MediaFiles with TableInfo<$MediaFilesTable, MediaFile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaFilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta('sourceId');
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storageKeyMeta = const VerificationMeta('storageKey');
  @override
  late final GeneratedColumn<String> storageKey = GeneratedColumn<String>(
    'storage_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta('fileName');
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parsedTitleMeta = const VerificationMeta('parsedTitle');
  @override
  late final GeneratedColumn<String> parsedTitle = GeneratedColumn<String>(
    'parsed_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parsedYearMeta = const VerificationMeta('parsedYear');
  @override
  late final GeneratedColumn<int> parsedYear = GeneratedColumn<int>(
    'parsed_year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parsedSeasonMeta = const VerificationMeta('parsedSeason');
  @override
  late final GeneratedColumn<int> parsedSeason = GeneratedColumn<int>(
    'parsed_season',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parsedEpisodeMeta = const VerificationMeta('parsedEpisode');
  @override
  late final GeneratedColumn<int> parsedEpisode = GeneratedColumn<int>(
    'parsed_episode',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MediaType, String> mediaType = GeneratedColumn<String>(
    'media_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<MediaType>($MediaFilesTable.$convertermediaType);
  static const VerificationMeta _explicitTmdbIdMeta = const VerificationMeta('explicitTmdbId');
  @override
  late final GeneratedColumn<String> explicitTmdbId = GeneratedColumn<String>(
    'explicit_tmdb_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _movieTmdbIdMeta = const VerificationMeta('movieTmdbId');
  @override
  late final GeneratedColumn<String> movieTmdbId = GeneratedColumn<String>(
    'movie_tmdb_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tvShowTmdbIdMeta = const VerificationMeta('tvShowTmdbId');
  @override
  late final GeneratedColumn<String> tvShowTmdbId = GeneratedColumn<String>(
    'tv_show_tmdb_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _episodeTmdbIdMeta = const VerificationMeta('episodeTmdbId');
  @override
  late final GeneratedColumn<String> episodeTmdbId = GeneratedColumn<String>(
    'episode_tmdb_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MetadataMatchStatus, String> metadataMatchStatus =
      GeneratedColumn<String>(
        'metadata_match_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MetadataMatchStatus>($MediaFilesTable.$convertermetadataMatchStatus);
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
    'size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _containerMeta = const VerificationMeta('container');
  @override
  late final GeneratedColumn<String> container = GeneratedColumn<String>(
    'container',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _videoCodecMeta = const VerificationMeta('videoCodec');
  @override
  late final GeneratedColumn<String> videoCodec = GeneratedColumn<String>(
    'video_codec',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _audioCodecMeta = const VerificationMeta('audioCodec');
  @override
  late final GeneratedColumn<String> audioCodec = GeneratedColumn<String>(
    'audio_codec',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _audioChannelsMeta = const VerificationMeta('audioChannels');
  @override
  late final GeneratedColumn<String> audioChannels = GeneratedColumn<String>(
    'audio_channels',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isHdrMeta = const VerificationMeta('isHdr');
  @override
  late final GeneratedColumn<bool> isHdr = GeneratedColumn<bool>(
    'is_hdr',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_hdr" IN (0, 1))'),
  );
  static const VerificationMeta _hdrFormatMeta = const VerificationMeta('hdrFormat');
  @override
  late final GeneratedColumn<String> hdrFormat = GeneratedColumn<String>(
    'hdr_format',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionLabelMeta = const VerificationMeta('versionLabel');
  @override
  late final GeneratedColumn<String> versionLabel = GeneratedColumn<String>(
    'version_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMeta = const VerificationMeta('duration');
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
    'duration',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<WatchStatus, String> watchStatus = GeneratedColumn<String>(
    'watch_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<WatchStatus>($MediaFilesTable.$converterwatchStatus);
  static const VerificationMeta _lastWatchedAtMeta = const VerificationMeta('lastWatchedAt');
  @override
  late final GeneratedColumn<DateTime> lastWatchedAt = GeneratedColumn<DateTime>(
    'last_watched_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_favorite" IN (0, 1))'),
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta('addedAt');
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceId,
    storageKey,
    path,
    fileName,
    parsedTitle,
    parsedYear,
    parsedSeason,
    parsedEpisode,
    mediaType,
    explicitTmdbId,
    movieTmdbId,
    tvShowTmdbId,
    episodeTmdbId,
    metadataMatchStatus,
    size,
    container,
    width,
    height,
    videoCodec,
    audioCodec,
    audioChannels,
    isHdr,
    hdrFormat,
    versionLabel,
    duration,
    position,
    watchStatus,
    lastWatchedAt,
    isFavorite,
    addedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_files';
  @override
  VerificationContext validateIntegrity(Insertable<MediaFile> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source_id')) {
      context.handle(_sourceIdMeta, sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta));
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('storage_key')) {
      context.handle(_storageKeyMeta, storageKey.isAcceptableOrUnknown(data['storage_key']!, _storageKeyMeta));
    } else if (isInserting) {
      context.missing(_storageKeyMeta);
    }
    if (data.containsKey('path')) {
      context.handle(_pathMeta, path.isAcceptableOrUnknown(data['path']!, _pathMeta));
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(_fileNameMeta, fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta));
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('parsed_title')) {
      context.handle(_parsedTitleMeta, parsedTitle.isAcceptableOrUnknown(data['parsed_title']!, _parsedTitleMeta));
    } else if (isInserting) {
      context.missing(_parsedTitleMeta);
    }
    if (data.containsKey('parsed_year')) {
      context.handle(_parsedYearMeta, parsedYear.isAcceptableOrUnknown(data['parsed_year']!, _parsedYearMeta));
    }
    if (data.containsKey('parsed_season')) {
      context.handle(_parsedSeasonMeta, parsedSeason.isAcceptableOrUnknown(data['parsed_season']!, _parsedSeasonMeta));
    }
    if (data.containsKey('parsed_episode')) {
      context.handle(
        _parsedEpisodeMeta,
        parsedEpisode.isAcceptableOrUnknown(data['parsed_episode']!, _parsedEpisodeMeta),
      );
    }
    if (data.containsKey('explicit_tmdb_id')) {
      context.handle(
        _explicitTmdbIdMeta,
        explicitTmdbId.isAcceptableOrUnknown(data['explicit_tmdb_id']!, _explicitTmdbIdMeta),
      );
    }
    if (data.containsKey('movie_tmdb_id')) {
      context.handle(_movieTmdbIdMeta, movieTmdbId.isAcceptableOrUnknown(data['movie_tmdb_id']!, _movieTmdbIdMeta));
    }
    if (data.containsKey('tv_show_tmdb_id')) {
      context.handle(
        _tvShowTmdbIdMeta,
        tvShowTmdbId.isAcceptableOrUnknown(data['tv_show_tmdb_id']!, _tvShowTmdbIdMeta),
      );
    }
    if (data.containsKey('episode_tmdb_id')) {
      context.handle(
        _episodeTmdbIdMeta,
        episodeTmdbId.isAcceptableOrUnknown(data['episode_tmdb_id']!, _episodeTmdbIdMeta),
      );
    }
    if (data.containsKey('size')) {
      context.handle(_sizeMeta, size.isAcceptableOrUnknown(data['size']!, _sizeMeta));
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    if (data.containsKey('container')) {
      context.handle(_containerMeta, container.isAcceptableOrUnknown(data['container']!, _containerMeta));
    }
    if (data.containsKey('width')) {
      context.handle(_widthMeta, width.isAcceptableOrUnknown(data['width']!, _widthMeta));
    }
    if (data.containsKey('height')) {
      context.handle(_heightMeta, height.isAcceptableOrUnknown(data['height']!, _heightMeta));
    }
    if (data.containsKey('video_codec')) {
      context.handle(_videoCodecMeta, videoCodec.isAcceptableOrUnknown(data['video_codec']!, _videoCodecMeta));
    }
    if (data.containsKey('audio_codec')) {
      context.handle(_audioCodecMeta, audioCodec.isAcceptableOrUnknown(data['audio_codec']!, _audioCodecMeta));
    }
    if (data.containsKey('audio_channels')) {
      context.handle(
        _audioChannelsMeta,
        audioChannels.isAcceptableOrUnknown(data['audio_channels']!, _audioChannelsMeta),
      );
    }
    if (data.containsKey('is_hdr')) {
      context.handle(_isHdrMeta, isHdr.isAcceptableOrUnknown(data['is_hdr']!, _isHdrMeta));
    } else if (isInserting) {
      context.missing(_isHdrMeta);
    }
    if (data.containsKey('hdr_format')) {
      context.handle(_hdrFormatMeta, hdrFormat.isAcceptableOrUnknown(data['hdr_format']!, _hdrFormatMeta));
    }
    if (data.containsKey('version_label')) {
      context.handle(_versionLabelMeta, versionLabel.isAcceptableOrUnknown(data['version_label']!, _versionLabelMeta));
    }
    if (data.containsKey('duration')) {
      context.handle(_durationMeta, duration.isAcceptableOrUnknown(data['duration']!, _durationMeta));
    } else if (isInserting) {
      context.missing(_durationMeta);
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta, position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('last_watched_at')) {
      context.handle(
        _lastWatchedAtMeta,
        lastWatchedAt.isAcceptableOrUnknown(data['last_watched_at']!, _lastWatchedAtMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(_isFavoriteMeta, isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta));
    } else if (isInserting) {
      context.missing(_isFavoriteMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(_addedAtMeta, addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta));
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MediaFile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaFile(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      sourceId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}source_id'])!,
      path: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}path'])!,
      fileName: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}file_name'])!,
      parsedTitle: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}parsed_title'])!,
      parsedYear: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}parsed_year']),
      parsedSeason: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}parsed_season']),
      parsedEpisode: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}parsed_episode']),
      mediaType: $MediaFilesTable.$convertermediaType.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}media_type'])!,
      ),
      explicitTmdbId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}explicit_tmdb_id'],
      ),
      metadataMatchStatus: $MediaFilesTable.$convertermetadataMatchStatus.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}metadata_match_status'])!,
      ),
      movieTmdbId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}movie_tmdb_id']),
      tvShowTmdbId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}tv_show_tmdb_id']),
      episodeTmdbId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}episode_tmdb_id']),
      size: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}size'])!,
      container: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}container']),
      width: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}width']),
      height: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}height']),
      videoCodec: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}video_codec']),
      audioCodec: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}audio_codec']),
      audioChannels: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}audio_channels']),
      isHdr: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_hdr'])!,
      hdrFormat: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}hdr_format']),
      versionLabel: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}version_label']),
      duration: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}duration'])!,
      position: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}position'])!,
      watchStatus: $MediaFilesTable.$converterwatchStatus.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}watch_status'])!,
      ),
      lastWatchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_watched_at'],
      ),
      isFavorite: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
      addedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}added_at'])!,
    );
  }

  @override
  $MediaFilesTable createAlias(String alias) {
    return $MediaFilesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MediaType, String, String> $convertermediaType = const EnumNameConverter<MediaType>(
    MediaType.values,
  );
  static JsonTypeConverter2<MetadataMatchStatus, String, String> $convertermetadataMatchStatus =
      const EnumNameConverter<MetadataMatchStatus>(MetadataMatchStatus.values);
  static JsonTypeConverter2<WatchStatus, String, String> $converterwatchStatus = const EnumNameConverter<WatchStatus>(
    WatchStatus.values,
  );
}

class MediaFilesCompanion extends UpdateCompanion<MediaFile> {
  final Value<int> id;
  final Value<String> sourceId;
  final Value<String> storageKey;
  final Value<String> path;
  final Value<String> fileName;
  final Value<String> parsedTitle;
  final Value<int?> parsedYear;
  final Value<int?> parsedSeason;
  final Value<int?> parsedEpisode;
  final Value<MediaType> mediaType;
  final Value<String?> explicitTmdbId;
  final Value<String?> movieTmdbId;
  final Value<String?> tvShowTmdbId;
  final Value<String?> episodeTmdbId;
  final Value<MetadataMatchStatus> metadataMatchStatus;
  final Value<int> size;
  final Value<String?> container;
  final Value<int?> width;
  final Value<int?> height;
  final Value<String?> videoCodec;
  final Value<String?> audioCodec;
  final Value<String?> audioChannels;
  final Value<bool> isHdr;
  final Value<String?> hdrFormat;
  final Value<String?> versionLabel;
  final Value<int> duration;
  final Value<int> position;
  final Value<WatchStatus> watchStatus;
  final Value<DateTime?> lastWatchedAt;
  final Value<bool> isFavorite;
  final Value<DateTime> addedAt;
  const MediaFilesCompanion({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.storageKey = const Value.absent(),
    this.path = const Value.absent(),
    this.fileName = const Value.absent(),
    this.parsedTitle = const Value.absent(),
    this.parsedYear = const Value.absent(),
    this.parsedSeason = const Value.absent(),
    this.parsedEpisode = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.explicitTmdbId = const Value.absent(),
    this.movieTmdbId = const Value.absent(),
    this.tvShowTmdbId = const Value.absent(),
    this.episodeTmdbId = const Value.absent(),
    this.metadataMatchStatus = const Value.absent(),
    this.size = const Value.absent(),
    this.container = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.videoCodec = const Value.absent(),
    this.audioCodec = const Value.absent(),
    this.audioChannels = const Value.absent(),
    this.isHdr = const Value.absent(),
    this.hdrFormat = const Value.absent(),
    this.versionLabel = const Value.absent(),
    this.duration = const Value.absent(),
    this.position = const Value.absent(),
    this.watchStatus = const Value.absent(),
    this.lastWatchedAt = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.addedAt = const Value.absent(),
  });
  MediaFilesCompanion.insert({
    this.id = const Value.absent(),
    required String sourceId,
    required String storageKey,
    required String path,
    required String fileName,
    required String parsedTitle,
    this.parsedYear = const Value.absent(),
    this.parsedSeason = const Value.absent(),
    this.parsedEpisode = const Value.absent(),
    required MediaType mediaType,
    this.explicitTmdbId = const Value.absent(),
    this.movieTmdbId = const Value.absent(),
    this.tvShowTmdbId = const Value.absent(),
    this.episodeTmdbId = const Value.absent(),
    required MetadataMatchStatus metadataMatchStatus,
    required int size,
    this.container = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.videoCodec = const Value.absent(),
    this.audioCodec = const Value.absent(),
    this.audioChannels = const Value.absent(),
    required bool isHdr,
    this.hdrFormat = const Value.absent(),
    this.versionLabel = const Value.absent(),
    required int duration,
    required int position,
    required WatchStatus watchStatus,
    this.lastWatchedAt = const Value.absent(),
    required bool isFavorite,
    required DateTime addedAt,
  }) : sourceId = Value(sourceId),
       storageKey = Value(storageKey),
       path = Value(path),
       fileName = Value(fileName),
       parsedTitle = Value(parsedTitle),
       mediaType = Value(mediaType),
       metadataMatchStatus = Value(metadataMatchStatus),
       size = Value(size),
       isHdr = Value(isHdr),
       duration = Value(duration),
       position = Value(position),
       watchStatus = Value(watchStatus),
       isFavorite = Value(isFavorite),
       addedAt = Value(addedAt);
  static Insertable<MediaFile> custom({
    Expression<int>? id,
    Expression<String>? sourceId,
    Expression<String>? storageKey,
    Expression<String>? path,
    Expression<String>? fileName,
    Expression<String>? parsedTitle,
    Expression<int>? parsedYear,
    Expression<int>? parsedSeason,
    Expression<int>? parsedEpisode,
    Expression<String>? mediaType,
    Expression<String>? explicitTmdbId,
    Expression<String>? movieTmdbId,
    Expression<String>? tvShowTmdbId,
    Expression<String>? episodeTmdbId,
    Expression<String>? metadataMatchStatus,
    Expression<int>? size,
    Expression<String>? container,
    Expression<int>? width,
    Expression<int>? height,
    Expression<String>? videoCodec,
    Expression<String>? audioCodec,
    Expression<String>? audioChannels,
    Expression<bool>? isHdr,
    Expression<String>? hdrFormat,
    Expression<String>? versionLabel,
    Expression<int>? duration,
    Expression<int>? position,
    Expression<String>? watchStatus,
    Expression<DateTime>? lastWatchedAt,
    Expression<bool>? isFavorite,
    Expression<DateTime>? addedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceId != null) 'source_id': sourceId,
      if (storageKey != null) 'storage_key': storageKey,
      if (path != null) 'path': path,
      if (fileName != null) 'file_name': fileName,
      if (parsedTitle != null) 'parsed_title': parsedTitle,
      if (parsedYear != null) 'parsed_year': parsedYear,
      if (parsedSeason != null) 'parsed_season': parsedSeason,
      if (parsedEpisode != null) 'parsed_episode': parsedEpisode,
      if (mediaType != null) 'media_type': mediaType,
      if (explicitTmdbId != null) 'explicit_tmdb_id': explicitTmdbId,
      if (movieTmdbId != null) 'movie_tmdb_id': movieTmdbId,
      if (tvShowTmdbId != null) 'tv_show_tmdb_id': tvShowTmdbId,
      if (episodeTmdbId != null) 'episode_tmdb_id': episodeTmdbId,
      if (metadataMatchStatus != null) 'metadata_match_status': metadataMatchStatus,
      if (size != null) 'size': size,
      if (container != null) 'container': container,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (videoCodec != null) 'video_codec': videoCodec,
      if (audioCodec != null) 'audio_codec': audioCodec,
      if (audioChannels != null) 'audio_channels': audioChannels,
      if (isHdr != null) 'is_hdr': isHdr,
      if (hdrFormat != null) 'hdr_format': hdrFormat,
      if (versionLabel != null) 'version_label': versionLabel,
      if (duration != null) 'duration': duration,
      if (position != null) 'position': position,
      if (watchStatus != null) 'watch_status': watchStatus,
      if (lastWatchedAt != null) 'last_watched_at': lastWatchedAt,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (addedAt != null) 'added_at': addedAt,
    });
  }

  MediaFilesCompanion copyWith({
    Value<int>? id,
    Value<String>? sourceId,
    Value<String>? storageKey,
    Value<String>? path,
    Value<String>? fileName,
    Value<String>? parsedTitle,
    Value<int?>? parsedYear,
    Value<int?>? parsedSeason,
    Value<int?>? parsedEpisode,
    Value<MediaType>? mediaType,
    Value<String?>? explicitTmdbId,
    Value<String?>? movieTmdbId,
    Value<String?>? tvShowTmdbId,
    Value<String?>? episodeTmdbId,
    Value<MetadataMatchStatus>? metadataMatchStatus,
    Value<int>? size,
    Value<String?>? container,
    Value<int?>? width,
    Value<int?>? height,
    Value<String?>? videoCodec,
    Value<String?>? audioCodec,
    Value<String?>? audioChannels,
    Value<bool>? isHdr,
    Value<String?>? hdrFormat,
    Value<String?>? versionLabel,
    Value<int>? duration,
    Value<int>? position,
    Value<WatchStatus>? watchStatus,
    Value<DateTime?>? lastWatchedAt,
    Value<bool>? isFavorite,
    Value<DateTime>? addedAt,
  }) {
    return MediaFilesCompanion(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      storageKey: storageKey ?? this.storageKey,
      path: path ?? this.path,
      fileName: fileName ?? this.fileName,
      parsedTitle: parsedTitle ?? this.parsedTitle,
      parsedYear: parsedYear ?? this.parsedYear,
      parsedSeason: parsedSeason ?? this.parsedSeason,
      parsedEpisode: parsedEpisode ?? this.parsedEpisode,
      mediaType: mediaType ?? this.mediaType,
      explicitTmdbId: explicitTmdbId ?? this.explicitTmdbId,
      movieTmdbId: movieTmdbId ?? this.movieTmdbId,
      tvShowTmdbId: tvShowTmdbId ?? this.tvShowTmdbId,
      episodeTmdbId: episodeTmdbId ?? this.episodeTmdbId,
      metadataMatchStatus: metadataMatchStatus ?? this.metadataMatchStatus,
      size: size ?? this.size,
      container: container ?? this.container,
      width: width ?? this.width,
      height: height ?? this.height,
      videoCodec: videoCodec ?? this.videoCodec,
      audioCodec: audioCodec ?? this.audioCodec,
      audioChannels: audioChannels ?? this.audioChannels,
      isHdr: isHdr ?? this.isHdr,
      hdrFormat: hdrFormat ?? this.hdrFormat,
      versionLabel: versionLabel ?? this.versionLabel,
      duration: duration ?? this.duration,
      position: position ?? this.position,
      watchStatus: watchStatus ?? this.watchStatus,
      lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (storageKey.present) {
      map['storage_key'] = Variable<String>(storageKey.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (parsedTitle.present) {
      map['parsed_title'] = Variable<String>(parsedTitle.value);
    }
    if (parsedYear.present) {
      map['parsed_year'] = Variable<int>(parsedYear.value);
    }
    if (parsedSeason.present) {
      map['parsed_season'] = Variable<int>(parsedSeason.value);
    }
    if (parsedEpisode.present) {
      map['parsed_episode'] = Variable<int>(parsedEpisode.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>($MediaFilesTable.$convertermediaType.toSql(mediaType.value));
    }
    if (explicitTmdbId.present) {
      map['explicit_tmdb_id'] = Variable<String>(explicitTmdbId.value);
    }
    if (movieTmdbId.present) {
      map['movie_tmdb_id'] = Variable<String>(movieTmdbId.value);
    }
    if (tvShowTmdbId.present) {
      map['tv_show_tmdb_id'] = Variable<String>(tvShowTmdbId.value);
    }
    if (episodeTmdbId.present) {
      map['episode_tmdb_id'] = Variable<String>(episodeTmdbId.value);
    }
    if (metadataMatchStatus.present) {
      map['metadata_match_status'] = Variable<String>(
        $MediaFilesTable.$convertermetadataMatchStatus.toSql(metadataMatchStatus.value),
      );
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (container.present) {
      map['container'] = Variable<String>(container.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (videoCodec.present) {
      map['video_codec'] = Variable<String>(videoCodec.value);
    }
    if (audioCodec.present) {
      map['audio_codec'] = Variable<String>(audioCodec.value);
    }
    if (audioChannels.present) {
      map['audio_channels'] = Variable<String>(audioChannels.value);
    }
    if (isHdr.present) {
      map['is_hdr'] = Variable<bool>(isHdr.value);
    }
    if (hdrFormat.present) {
      map['hdr_format'] = Variable<String>(hdrFormat.value);
    }
    if (versionLabel.present) {
      map['version_label'] = Variable<String>(versionLabel.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (watchStatus.present) {
      map['watch_status'] = Variable<String>($MediaFilesTable.$converterwatchStatus.toSql(watchStatus.value));
    }
    if (lastWatchedAt.present) {
      map['last_watched_at'] = Variable<DateTime>(lastWatchedAt.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaFilesCompanion(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('storageKey: $storageKey, ')
          ..write('path: $path, ')
          ..write('fileName: $fileName, ')
          ..write('parsedTitle: $parsedTitle, ')
          ..write('parsedYear: $parsedYear, ')
          ..write('parsedSeason: $parsedSeason, ')
          ..write('parsedEpisode: $parsedEpisode, ')
          ..write('mediaType: $mediaType, ')
          ..write('explicitTmdbId: $explicitTmdbId, ')
          ..write('movieTmdbId: $movieTmdbId, ')
          ..write('tvShowTmdbId: $tvShowTmdbId, ')
          ..write('episodeTmdbId: $episodeTmdbId, ')
          ..write('metadataMatchStatus: $metadataMatchStatus, ')
          ..write('size: $size, ')
          ..write('container: $container, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('videoCodec: $videoCodec, ')
          ..write('audioCodec: $audioCodec, ')
          ..write('audioChannels: $audioChannels, ')
          ..write('isHdr: $isHdr, ')
          ..write('hdrFormat: $hdrFormat, ')
          ..write('versionLabel: $versionLabel, ')
          ..write('duration: $duration, ')
          ..write('position: $position, ')
          ..write('watchStatus: $watchStatus, ')
          ..write('lastWatchedAt: $lastWatchedAt, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }
}

class _$MediaFileInsertable implements Insertable<MediaFile> {
  MediaFile _object;
  _$MediaFileInsertable(this._object);
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    return MediaFilesCompanion(
      id: Value(_object.id),
      sourceId: Value(_object.sourceId),
      storageKey: Value(_object.storageKey),
      path: Value(_object.path),
      fileName: Value(_object.fileName),
      parsedTitle: Value(_object.parsedTitle),
      parsedYear: Value(_object.parsedYear),
      parsedSeason: Value(_object.parsedSeason),
      parsedEpisode: Value(_object.parsedEpisode),
      mediaType: Value(_object.mediaType),
      explicitTmdbId: Value(_object.explicitTmdbId),
      movieTmdbId: Value(_object.movieTmdbId),
      tvShowTmdbId: Value(_object.tvShowTmdbId),
      episodeTmdbId: Value(_object.episodeTmdbId),
      metadataMatchStatus: Value(_object.metadataMatchStatus),
      size: Value(_object.size),
      container: Value(_object.container),
      width: Value(_object.width),
      height: Value(_object.height),
      videoCodec: Value(_object.videoCodec),
      audioCodec: Value(_object.audioCodec),
      audioChannels: Value(_object.audioChannels),
      isHdr: Value(_object.isHdr),
      hdrFormat: Value(_object.hdrFormat),
      versionLabel: Value(_object.versionLabel),
      duration: Value(_object.duration),
      position: Value(_object.position),
      watchStatus: Value(_object.watchStatus),
      lastWatchedAt: Value(_object.lastWatchedAt),
      isFavorite: Value(_object.isFavorite),
      addedAt: Value(_object.addedAt),
    ).toColumns(false);
  }
}

extension MediaFileToInsertable on MediaFile {
  _$MediaFileInsertable toInsertable() {
    return _$MediaFileInsertable(this);
  }
}

class $MoviesTable extends Movies with TableInfo<$MoviesTable, Movie> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MoviesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tmdbIdMeta = const VerificationMeta('tmdbId');
  @override
  late final GeneratedColumn<String> tmdbId = GeneratedColumn<String>(
    'tmdb_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalTitleMeta = const VerificationMeta('originalTitle');
  @override
  late final GeneratedColumn<String> originalTitle = GeneratedColumn<String>(
    'original_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _releaseYearMeta = const VerificationMeta('releaseYear');
  @override
  late final GeneratedColumn<int> releaseYear = GeneratedColumn<int>(
    'release_year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _releaseDateMeta = const VerificationMeta('releaseDate');
  @override
  late final GeneratedColumn<DateTime> releaseDate = GeneratedColumn<DateTime>(
    'release_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _posterUrlMeta = const VerificationMeta('posterUrl');
  @override
  late final GeneratedColumn<String> posterUrl = GeneratedColumn<String>(
    'poster_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _backdropUrlMeta = const VerificationMeta('backdropUrl');
  @override
  late final GeneratedColumn<String> backdropUrl = GeneratedColumn<String>(
    'backdrop_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _logoUrlMeta = const VerificationMeta('logoUrl');
  @override
  late final GeneratedColumn<String> logoUrl = GeneratedColumn<String>(
    'logo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overviewMeta = const VerificationMeta('overview');
  @override
  late final GeneratedColumn<String> overview = GeneratedColumn<String>(
    'overview',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _certificationMeta = const VerificationMeta('certification');
  @override
  late final GeneratedColumn<String> certification = GeneratedColumn<String>(
    'certification',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> genres = GeneratedColumn<String>(
    'genres',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<List<String>>($MoviesTable.$convertergenres);
  @override
  late final GeneratedColumnWithTypeConverter<List<Artist>, String> cast = GeneratedColumn<String>(
    'cast',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<List<Artist>>($MoviesTable.$convertercast);
  @override
  List<GeneratedColumn> get $columns => [
    tmdbId,
    title,
    originalTitle,
    releaseYear,
    releaseDate,
    posterUrl,
    backdropUrl,
    logoUrl,
    overview,
    certification,
    rating,
    genres,
    cast,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'movies';
  @override
  VerificationContext validateIntegrity(Insertable<Movie> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tmdb_id')) {
      context.handle(_tmdbIdMeta, tmdbId.isAcceptableOrUnknown(data['tmdb_id']!, _tmdbIdMeta));
    } else if (isInserting) {
      context.missing(_tmdbIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('original_title')) {
      context.handle(
        _originalTitleMeta,
        originalTitle.isAcceptableOrUnknown(data['original_title']!, _originalTitleMeta),
      );
    }
    if (data.containsKey('release_year')) {
      context.handle(_releaseYearMeta, releaseYear.isAcceptableOrUnknown(data['release_year']!, _releaseYearMeta));
    }
    if (data.containsKey('release_date')) {
      context.handle(_releaseDateMeta, releaseDate.isAcceptableOrUnknown(data['release_date']!, _releaseDateMeta));
    }
    if (data.containsKey('poster_url')) {
      context.handle(_posterUrlMeta, posterUrl.isAcceptableOrUnknown(data['poster_url']!, _posterUrlMeta));
    }
    if (data.containsKey('backdrop_url')) {
      context.handle(_backdropUrlMeta, backdropUrl.isAcceptableOrUnknown(data['backdrop_url']!, _backdropUrlMeta));
    }
    if (data.containsKey('logo_url')) {
      context.handle(_logoUrlMeta, logoUrl.isAcceptableOrUnknown(data['logo_url']!, _logoUrlMeta));
    }
    if (data.containsKey('overview')) {
      context.handle(_overviewMeta, overview.isAcceptableOrUnknown(data['overview']!, _overviewMeta));
    }
    if (data.containsKey('certification')) {
      context.handle(
        _certificationMeta,
        certification.isAcceptableOrUnknown(data['certification']!, _certificationMeta),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(_ratingMeta, rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta));
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tmdbId};
  @override
  Movie map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Movie(
      tmdbId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}tmdb_id'])!,
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      originalTitle: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}original_title']),
      releaseYear: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}release_year']),
      releaseDate: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}release_date']),
      posterUrl: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}poster_url']),
      backdropUrl: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}backdrop_url']),
      logoUrl: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}logo_url']),
      overview: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}overview']),
      certification: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}certification']),
      rating: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}rating'])!,
      genres: $MoviesTable.$convertergenres.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}genres'])!,
      ),
      cast: $MoviesTable.$convertercast.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}cast'])!,
      ),
    );
  }

  @override
  $MoviesTable createAlias(String alias) {
    return $MoviesTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $convertergenres = const StringListConverter();
  static TypeConverter<List<Artist>, String> $convertercast = const ArtistListConverter();
}

class MoviesCompanion extends UpdateCompanion<Movie> {
  final Value<String> tmdbId;
  final Value<String> title;
  final Value<String?> originalTitle;
  final Value<int?> releaseYear;
  final Value<DateTime?> releaseDate;
  final Value<String?> posterUrl;
  final Value<String?> backdropUrl;
  final Value<String?> logoUrl;
  final Value<String?> overview;
  final Value<String?> certification;
  final Value<double> rating;
  final Value<List<String>> genres;
  final Value<List<Artist>> cast;
  final Value<int> rowid;
  const MoviesCompanion({
    this.tmdbId = const Value.absent(),
    this.title = const Value.absent(),
    this.originalTitle = const Value.absent(),
    this.releaseYear = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.posterUrl = const Value.absent(),
    this.backdropUrl = const Value.absent(),
    this.logoUrl = const Value.absent(),
    this.overview = const Value.absent(),
    this.certification = const Value.absent(),
    this.rating = const Value.absent(),
    this.genres = const Value.absent(),
    this.cast = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MoviesCompanion.insert({
    required String tmdbId,
    required String title,
    this.originalTitle = const Value.absent(),
    this.releaseYear = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.posterUrl = const Value.absent(),
    this.backdropUrl = const Value.absent(),
    this.logoUrl = const Value.absent(),
    this.overview = const Value.absent(),
    this.certification = const Value.absent(),
    required double rating,
    required List<String> genres,
    required List<Artist> cast,
    this.rowid = const Value.absent(),
  }) : tmdbId = Value(tmdbId),
       title = Value(title),
       rating = Value(rating),
       genres = Value(genres),
       cast = Value(cast);
  static Insertable<Movie> custom({
    Expression<String>? tmdbId,
    Expression<String>? title,
    Expression<String>? originalTitle,
    Expression<int>? releaseYear,
    Expression<DateTime>? releaseDate,
    Expression<String>? posterUrl,
    Expression<String>? backdropUrl,
    Expression<String>? logoUrl,
    Expression<String>? overview,
    Expression<String>? certification,
    Expression<double>? rating,
    Expression<String>? genres,
    Expression<String>? cast,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tmdbId != null) 'tmdb_id': tmdbId,
      if (title != null) 'title': title,
      if (originalTitle != null) 'original_title': originalTitle,
      if (releaseYear != null) 'release_year': releaseYear,
      if (releaseDate != null) 'release_date': releaseDate,
      if (posterUrl != null) 'poster_url': posterUrl,
      if (backdropUrl != null) 'backdrop_url': backdropUrl,
      if (logoUrl != null) 'logo_url': logoUrl,
      if (overview != null) 'overview': overview,
      if (certification != null) 'certification': certification,
      if (rating != null) 'rating': rating,
      if (genres != null) 'genres': genres,
      if (cast != null) 'cast': cast,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MoviesCompanion copyWith({
    Value<String>? tmdbId,
    Value<String>? title,
    Value<String?>? originalTitle,
    Value<int?>? releaseYear,
    Value<DateTime?>? releaseDate,
    Value<String?>? posterUrl,
    Value<String?>? backdropUrl,
    Value<String?>? logoUrl,
    Value<String?>? overview,
    Value<String?>? certification,
    Value<double>? rating,
    Value<List<String>>? genres,
    Value<List<Artist>>? cast,
    Value<int>? rowid,
  }) {
    return MoviesCompanion(
      tmdbId: tmdbId ?? this.tmdbId,
      title: title ?? this.title,
      originalTitle: originalTitle ?? this.originalTitle,
      releaseYear: releaseYear ?? this.releaseYear,
      releaseDate: releaseDate ?? this.releaseDate,
      posterUrl: posterUrl ?? this.posterUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      overview: overview ?? this.overview,
      certification: certification ?? this.certification,
      rating: rating ?? this.rating,
      genres: genres ?? this.genres,
      cast: cast ?? this.cast,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tmdbId.present) {
      map['tmdb_id'] = Variable<String>(tmdbId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (originalTitle.present) {
      map['original_title'] = Variable<String>(originalTitle.value);
    }
    if (releaseYear.present) {
      map['release_year'] = Variable<int>(releaseYear.value);
    }
    if (releaseDate.present) {
      map['release_date'] = Variable<DateTime>(releaseDate.value);
    }
    if (posterUrl.present) {
      map['poster_url'] = Variable<String>(posterUrl.value);
    }
    if (backdropUrl.present) {
      map['backdrop_url'] = Variable<String>(backdropUrl.value);
    }
    if (logoUrl.present) {
      map['logo_url'] = Variable<String>(logoUrl.value);
    }
    if (overview.present) {
      map['overview'] = Variable<String>(overview.value);
    }
    if (certification.present) {
      map['certification'] = Variable<String>(certification.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (genres.present) {
      map['genres'] = Variable<String>($MoviesTable.$convertergenres.toSql(genres.value));
    }
    if (cast.present) {
      map['cast'] = Variable<String>($MoviesTable.$convertercast.toSql(cast.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MoviesCompanion(')
          ..write('tmdbId: $tmdbId, ')
          ..write('title: $title, ')
          ..write('originalTitle: $originalTitle, ')
          ..write('releaseYear: $releaseYear, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('backdropUrl: $backdropUrl, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('overview: $overview, ')
          ..write('certification: $certification, ')
          ..write('rating: $rating, ')
          ..write('genres: $genres, ')
          ..write('cast: $cast, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class _$MovieInsertable implements Insertable<Movie> {
  Movie _object;
  _$MovieInsertable(this._object);
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    return MoviesCompanion(
      tmdbId: Value(_object.tmdbId),
      title: Value(_object.title),
      originalTitle: Value(_object.originalTitle),
      releaseYear: Value(_object.releaseYear),
      releaseDate: Value(_object.releaseDate),
      posterUrl: Value(_object.posterUrl),
      backdropUrl: Value(_object.backdropUrl),
      logoUrl: Value(_object.logoUrl),
      overview: Value(_object.overview),
      certification: Value(_object.certification),
      rating: Value(_object.rating),
      genres: Value(_object.genres),
      cast: Value(_object.cast),
    ).toColumns(false);
  }
}

extension MovieToInsertable on Movie {
  _$MovieInsertable toInsertable() {
    return _$MovieInsertable(this);
  }
}

class $TVShowsTable extends TVShows with TableInfo<$TVShowsTable, TVShow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TVShowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tmdbIdMeta = const VerificationMeta('tmdbId');
  @override
  late final GeneratedColumn<String> tmdbId = GeneratedColumn<String>(
    'tmdb_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalTitleMeta = const VerificationMeta('originalTitle');
  @override
  late final GeneratedColumn<String> originalTitle = GeneratedColumn<String>(
    'original_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _releaseYearMeta = const VerificationMeta('releaseYear');
  @override
  late final GeneratedColumn<int> releaseYear = GeneratedColumn<int>(
    'release_year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _firstAirDateMeta = const VerificationMeta('firstAirDate');
  @override
  late final GeneratedColumn<DateTime> firstAirDate = GeneratedColumn<DateTime>(
    'first_air_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _posterUrlMeta = const VerificationMeta('posterUrl');
  @override
  late final GeneratedColumn<String> posterUrl = GeneratedColumn<String>(
    'poster_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _backdropUrlMeta = const VerificationMeta('backdropUrl');
  @override
  late final GeneratedColumn<String> backdropUrl = GeneratedColumn<String>(
    'backdrop_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _logoUrlMeta = const VerificationMeta('logoUrl');
  @override
  late final GeneratedColumn<String> logoUrl = GeneratedColumn<String>(
    'logo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overviewMeta = const VerificationMeta('overview');
  @override
  late final GeneratedColumn<String> overview = GeneratedColumn<String>(
    'overview',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _certificationMeta = const VerificationMeta('certification');
  @override
  late final GeneratedColumn<String> certification = GeneratedColumn<String>(
    'certification',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> genres = GeneratedColumn<String>(
    'genres',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<List<String>>($TVShowsTable.$convertergenres);
  @override
  late final GeneratedColumnWithTypeConverter<List<Artist>, String> cast = GeneratedColumn<String>(
    'cast',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<List<Artist>>($TVShowsTable.$convertercast);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _numberOfSeasonsMeta = const VerificationMeta('numberOfSeasons');
  @override
  late final GeneratedColumn<int> numberOfSeasons = GeneratedColumn<int>(
    'number_of_seasons',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _numberOfEpisodesMeta = const VerificationMeta('numberOfEpisodes');
  @override
  late final GeneratedColumn<int> numberOfEpisodes = GeneratedColumn<int>(
    'number_of_episodes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tmdbId,
    title,
    originalTitle,
    releaseYear,
    firstAirDate,
    posterUrl,
    backdropUrl,
    logoUrl,
    overview,
    certification,
    rating,
    genres,
    cast,
    status,
    numberOfSeasons,
    numberOfEpisodes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 't_v_shows';
  @override
  VerificationContext validateIntegrity(Insertable<TVShow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tmdb_id')) {
      context.handle(_tmdbIdMeta, tmdbId.isAcceptableOrUnknown(data['tmdb_id']!, _tmdbIdMeta));
    } else if (isInserting) {
      context.missing(_tmdbIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('original_title')) {
      context.handle(
        _originalTitleMeta,
        originalTitle.isAcceptableOrUnknown(data['original_title']!, _originalTitleMeta),
      );
    }
    if (data.containsKey('release_year')) {
      context.handle(_releaseYearMeta, releaseYear.isAcceptableOrUnknown(data['release_year']!, _releaseYearMeta));
    }
    if (data.containsKey('first_air_date')) {
      context.handle(_firstAirDateMeta, firstAirDate.isAcceptableOrUnknown(data['first_air_date']!, _firstAirDateMeta));
    }
    if (data.containsKey('poster_url')) {
      context.handle(_posterUrlMeta, posterUrl.isAcceptableOrUnknown(data['poster_url']!, _posterUrlMeta));
    }
    if (data.containsKey('backdrop_url')) {
      context.handle(_backdropUrlMeta, backdropUrl.isAcceptableOrUnknown(data['backdrop_url']!, _backdropUrlMeta));
    }
    if (data.containsKey('logo_url')) {
      context.handle(_logoUrlMeta, logoUrl.isAcceptableOrUnknown(data['logo_url']!, _logoUrlMeta));
    }
    if (data.containsKey('overview')) {
      context.handle(_overviewMeta, overview.isAcceptableOrUnknown(data['overview']!, _overviewMeta));
    }
    if (data.containsKey('certification')) {
      context.handle(
        _certificationMeta,
        certification.isAcceptableOrUnknown(data['certification']!, _certificationMeta),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(_ratingMeta, rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta));
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta, status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('number_of_seasons')) {
      context.handle(
        _numberOfSeasonsMeta,
        numberOfSeasons.isAcceptableOrUnknown(data['number_of_seasons']!, _numberOfSeasonsMeta),
      );
    }
    if (data.containsKey('number_of_episodes')) {
      context.handle(
        _numberOfEpisodesMeta,
        numberOfEpisodes.isAcceptableOrUnknown(data['number_of_episodes']!, _numberOfEpisodesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tmdbId};
  @override
  TVShow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TVShow(
      tmdbId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}tmdb_id'])!,
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      originalTitle: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}original_title']),
      releaseYear: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}release_year']),
      firstAirDate: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}first_air_date']),
      posterUrl: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}poster_url']),
      backdropUrl: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}backdrop_url']),
      logoUrl: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}logo_url']),
      overview: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}overview']),
      certification: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}certification']),
      rating: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}rating'])!,
      genres: $TVShowsTable.$convertergenres.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}genres'])!,
      ),
      cast: $TVShowsTable.$convertercast.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}cast'])!,
      ),
      status: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}status']),
      numberOfSeasons: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}number_of_seasons']),
      numberOfEpisodes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number_of_episodes'],
      ),
    );
  }

  @override
  $TVShowsTable createAlias(String alias) {
    return $TVShowsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $convertergenres = const StringListConverter();
  static TypeConverter<List<Artist>, String> $convertercast = const ArtistListConverter();
}

class TVShowsCompanion extends UpdateCompanion<TVShow> {
  final Value<String> tmdbId;
  final Value<String> title;
  final Value<String?> originalTitle;
  final Value<int?> releaseYear;
  final Value<DateTime?> firstAirDate;
  final Value<String?> posterUrl;
  final Value<String?> backdropUrl;
  final Value<String?> logoUrl;
  final Value<String?> overview;
  final Value<String?> certification;
  final Value<double> rating;
  final Value<List<String>> genres;
  final Value<List<Artist>> cast;
  final Value<String?> status;
  final Value<int?> numberOfSeasons;
  final Value<int?> numberOfEpisodes;
  final Value<int> rowid;
  const TVShowsCompanion({
    this.tmdbId = const Value.absent(),
    this.title = const Value.absent(),
    this.originalTitle = const Value.absent(),
    this.releaseYear = const Value.absent(),
    this.firstAirDate = const Value.absent(),
    this.posterUrl = const Value.absent(),
    this.backdropUrl = const Value.absent(),
    this.logoUrl = const Value.absent(),
    this.overview = const Value.absent(),
    this.certification = const Value.absent(),
    this.rating = const Value.absent(),
    this.genres = const Value.absent(),
    this.cast = const Value.absent(),
    this.status = const Value.absent(),
    this.numberOfSeasons = const Value.absent(),
    this.numberOfEpisodes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TVShowsCompanion.insert({
    required String tmdbId,
    required String title,
    this.originalTitle = const Value.absent(),
    this.releaseYear = const Value.absent(),
    this.firstAirDate = const Value.absent(),
    this.posterUrl = const Value.absent(),
    this.backdropUrl = const Value.absent(),
    this.logoUrl = const Value.absent(),
    this.overview = const Value.absent(),
    this.certification = const Value.absent(),
    required double rating,
    required List<String> genres,
    required List<Artist> cast,
    this.status = const Value.absent(),
    this.numberOfSeasons = const Value.absent(),
    this.numberOfEpisodes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tmdbId = Value(tmdbId),
       title = Value(title),
       rating = Value(rating),
       genres = Value(genres),
       cast = Value(cast);
  static Insertable<TVShow> custom({
    Expression<String>? tmdbId,
    Expression<String>? title,
    Expression<String>? originalTitle,
    Expression<int>? releaseYear,
    Expression<DateTime>? firstAirDate,
    Expression<String>? posterUrl,
    Expression<String>? backdropUrl,
    Expression<String>? logoUrl,
    Expression<String>? overview,
    Expression<String>? certification,
    Expression<double>? rating,
    Expression<String>? genres,
    Expression<String>? cast,
    Expression<String>? status,
    Expression<int>? numberOfSeasons,
    Expression<int>? numberOfEpisodes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tmdbId != null) 'tmdb_id': tmdbId,
      if (title != null) 'title': title,
      if (originalTitle != null) 'original_title': originalTitle,
      if (releaseYear != null) 'release_year': releaseYear,
      if (firstAirDate != null) 'first_air_date': firstAirDate,
      if (posterUrl != null) 'poster_url': posterUrl,
      if (backdropUrl != null) 'backdrop_url': backdropUrl,
      if (logoUrl != null) 'logo_url': logoUrl,
      if (overview != null) 'overview': overview,
      if (certification != null) 'certification': certification,
      if (rating != null) 'rating': rating,
      if (genres != null) 'genres': genres,
      if (cast != null) 'cast': cast,
      if (status != null) 'status': status,
      if (numberOfSeasons != null) 'number_of_seasons': numberOfSeasons,
      if (numberOfEpisodes != null) 'number_of_episodes': numberOfEpisodes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TVShowsCompanion copyWith({
    Value<String>? tmdbId,
    Value<String>? title,
    Value<String?>? originalTitle,
    Value<int?>? releaseYear,
    Value<DateTime?>? firstAirDate,
    Value<String?>? posterUrl,
    Value<String?>? backdropUrl,
    Value<String?>? logoUrl,
    Value<String?>? overview,
    Value<String?>? certification,
    Value<double>? rating,
    Value<List<String>>? genres,
    Value<List<Artist>>? cast,
    Value<String?>? status,
    Value<int?>? numberOfSeasons,
    Value<int?>? numberOfEpisodes,
    Value<int>? rowid,
  }) {
    return TVShowsCompanion(
      tmdbId: tmdbId ?? this.tmdbId,
      title: title ?? this.title,
      originalTitle: originalTitle ?? this.originalTitle,
      releaseYear: releaseYear ?? this.releaseYear,
      firstAirDate: firstAirDate ?? this.firstAirDate,
      posterUrl: posterUrl ?? this.posterUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      overview: overview ?? this.overview,
      certification: certification ?? this.certification,
      rating: rating ?? this.rating,
      genres: genres ?? this.genres,
      cast: cast ?? this.cast,
      status: status ?? this.status,
      numberOfSeasons: numberOfSeasons ?? this.numberOfSeasons,
      numberOfEpisodes: numberOfEpisodes ?? this.numberOfEpisodes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tmdbId.present) {
      map['tmdb_id'] = Variable<String>(tmdbId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (originalTitle.present) {
      map['original_title'] = Variable<String>(originalTitle.value);
    }
    if (releaseYear.present) {
      map['release_year'] = Variable<int>(releaseYear.value);
    }
    if (firstAirDate.present) {
      map['first_air_date'] = Variable<DateTime>(firstAirDate.value);
    }
    if (posterUrl.present) {
      map['poster_url'] = Variable<String>(posterUrl.value);
    }
    if (backdropUrl.present) {
      map['backdrop_url'] = Variable<String>(backdropUrl.value);
    }
    if (logoUrl.present) {
      map['logo_url'] = Variable<String>(logoUrl.value);
    }
    if (overview.present) {
      map['overview'] = Variable<String>(overview.value);
    }
    if (certification.present) {
      map['certification'] = Variable<String>(certification.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (genres.present) {
      map['genres'] = Variable<String>($TVShowsTable.$convertergenres.toSql(genres.value));
    }
    if (cast.present) {
      map['cast'] = Variable<String>($TVShowsTable.$convertercast.toSql(cast.value));
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (numberOfSeasons.present) {
      map['number_of_seasons'] = Variable<int>(numberOfSeasons.value);
    }
    if (numberOfEpisodes.present) {
      map['number_of_episodes'] = Variable<int>(numberOfEpisodes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TVShowsCompanion(')
          ..write('tmdbId: $tmdbId, ')
          ..write('title: $title, ')
          ..write('originalTitle: $originalTitle, ')
          ..write('releaseYear: $releaseYear, ')
          ..write('firstAirDate: $firstAirDate, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('backdropUrl: $backdropUrl, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('overview: $overview, ')
          ..write('certification: $certification, ')
          ..write('rating: $rating, ')
          ..write('genres: $genres, ')
          ..write('cast: $cast, ')
          ..write('status: $status, ')
          ..write('numberOfSeasons: $numberOfSeasons, ')
          ..write('numberOfEpisodes: $numberOfEpisodes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class _$TVShowInsertable implements Insertable<TVShow> {
  TVShow _object;
  _$TVShowInsertable(this._object);
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    return TVShowsCompanion(
      tmdbId: Value(_object.tmdbId),
      title: Value(_object.title),
      originalTitle: Value(_object.originalTitle),
      releaseYear: Value(_object.releaseYear),
      firstAirDate: Value(_object.firstAirDate),
      posterUrl: Value(_object.posterUrl),
      backdropUrl: Value(_object.backdropUrl),
      logoUrl: Value(_object.logoUrl),
      overview: Value(_object.overview),
      certification: Value(_object.certification),
      rating: Value(_object.rating),
      genres: Value(_object.genres),
      cast: Value(_object.cast),
      status: Value(_object.status),
      numberOfSeasons: Value(_object.numberOfSeasons),
      numberOfEpisodes: Value(_object.numberOfEpisodes),
    ).toColumns(false);
  }
}

extension TVShowToInsertable on TVShow {
  _$TVShowInsertable toInsertable() {
    return _$TVShowInsertable(this);
  }
}

class $SeasonsTable extends Seasons with TableInfo<$SeasonsTable, Season> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeasonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seasonKeyMeta = const VerificationMeta('seasonKey');
  @override
  late final GeneratedColumn<String> seasonKey = GeneratedColumn<String>(
    'season_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seasonNumberMeta = const VerificationMeta('seasonNumber');
  @override
  late final GeneratedColumn<int> seasonNumber = GeneratedColumn<int>(
    'season_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _posterUrlMeta = const VerificationMeta('posterUrl');
  @override
  late final GeneratedColumn<String> posterUrl = GeneratedColumn<String>(
    'poster_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overviewMeta = const VerificationMeta('overview');
  @override
  late final GeneratedColumn<String> overview = GeneratedColumn<String>(
    'overview',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _numberOfEpisodesMeta = const VerificationMeta('numberOfEpisodes');
  @override
  late final GeneratedColumn<int> numberOfEpisodes = GeneratedColumn<int>(
    'number_of_episodes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [seasonKey, seasonNumber, title, posterUrl, overview, numberOfEpisodes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'seasons';
  @override
  VerificationContext validateIntegrity(Insertable<Season> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('season_key')) {
      context.handle(_seasonKeyMeta, seasonKey.isAcceptableOrUnknown(data['season_key']!, _seasonKeyMeta));
    } else if (isInserting) {
      context.missing(_seasonKeyMeta);
    }
    if (data.containsKey('season_number')) {
      context.handle(_seasonNumberMeta, seasonNumber.isAcceptableOrUnknown(data['season_number']!, _seasonNumberMeta));
    } else if (isInserting) {
      context.missing(_seasonNumberMeta);
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('poster_url')) {
      context.handle(_posterUrlMeta, posterUrl.isAcceptableOrUnknown(data['poster_url']!, _posterUrlMeta));
    }
    if (data.containsKey('overview')) {
      context.handle(_overviewMeta, overview.isAcceptableOrUnknown(data['overview']!, _overviewMeta));
    }
    if (data.containsKey('number_of_episodes')) {
      context.handle(
        _numberOfEpisodesMeta,
        numberOfEpisodes.isAcceptableOrUnknown(data['number_of_episodes']!, _numberOfEpisodesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {seasonKey};
  @override
  Season map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Season(
      seasonKey: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}season_key'])!,
      seasonNumber: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}season_number'])!,
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      posterUrl: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}poster_url']),
      overview: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}overview']),
      numberOfEpisodes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number_of_episodes'],
      ),
    );
  }

  @override
  $SeasonsTable createAlias(String alias) {
    return $SeasonsTable(attachedDatabase, alias);
  }
}

class SeasonsCompanion extends UpdateCompanion<Season> {
  final Value<String> seasonKey;
  final Value<int> seasonNumber;
  final Value<String> title;
  final Value<String?> posterUrl;
  final Value<String?> overview;
  final Value<int?> numberOfEpisodes;
  final Value<int> rowid;
  const SeasonsCompanion({
    this.seasonKey = const Value.absent(),
    this.seasonNumber = const Value.absent(),
    this.title = const Value.absent(),
    this.posterUrl = const Value.absent(),
    this.overview = const Value.absent(),
    this.numberOfEpisodes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SeasonsCompanion.insert({
    required String seasonKey,
    required int seasonNumber,
    required String title,
    this.posterUrl = const Value.absent(),
    this.overview = const Value.absent(),
    this.numberOfEpisodes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : seasonKey = Value(seasonKey),
       seasonNumber = Value(seasonNumber),
       title = Value(title);
  static Insertable<Season> custom({
    Expression<String>? seasonKey,
    Expression<int>? seasonNumber,
    Expression<String>? title,
    Expression<String>? posterUrl,
    Expression<String>? overview,
    Expression<int>? numberOfEpisodes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (seasonKey != null) 'season_key': seasonKey,
      if (seasonNumber != null) 'season_number': seasonNumber,
      if (title != null) 'title': title,
      if (posterUrl != null) 'poster_url': posterUrl,
      if (overview != null) 'overview': overview,
      if (numberOfEpisodes != null) 'number_of_episodes': numberOfEpisodes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SeasonsCompanion copyWith({
    Value<String>? seasonKey,
    Value<int>? seasonNumber,
    Value<String>? title,
    Value<String?>? posterUrl,
    Value<String?>? overview,
    Value<int?>? numberOfEpisodes,
    Value<int>? rowid,
  }) {
    return SeasonsCompanion(
      seasonKey: seasonKey ?? this.seasonKey,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      title: title ?? this.title,
      posterUrl: posterUrl ?? this.posterUrl,
      overview: overview ?? this.overview,
      numberOfEpisodes: numberOfEpisodes ?? this.numberOfEpisodes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seasonKey.present) {
      map['season_key'] = Variable<String>(seasonKey.value);
    }
    if (seasonNumber.present) {
      map['season_number'] = Variable<int>(seasonNumber.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (posterUrl.present) {
      map['poster_url'] = Variable<String>(posterUrl.value);
    }
    if (overview.present) {
      map['overview'] = Variable<String>(overview.value);
    }
    if (numberOfEpisodes.present) {
      map['number_of_episodes'] = Variable<int>(numberOfEpisodes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeasonsCompanion(')
          ..write('seasonKey: $seasonKey, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('title: $title, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('overview: $overview, ')
          ..write('numberOfEpisodes: $numberOfEpisodes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class _$SeasonInsertable implements Insertable<Season> {
  Season _object;
  _$SeasonInsertable(this._object);
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    return SeasonsCompanion(
      seasonKey: Value(_object.seasonKey),
      seasonNumber: Value(_object.seasonNumber),
      title: Value(_object.title),
      posterUrl: Value(_object.posterUrl),
      overview: Value(_object.overview),
      numberOfEpisodes: Value(_object.numberOfEpisodes),
    ).toColumns(false);
  }
}

extension SeasonToInsertable on Season {
  _$SeasonInsertable toInsertable() {
    return _$SeasonInsertable(this);
  }
}

class $EpisodesTable extends Episodes with TableInfo<$EpisodesTable, Episode> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EpisodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tmdbIdMeta = const VerificationMeta('tmdbId');
  @override
  late final GeneratedColumn<String> tmdbId = GeneratedColumn<String>(
    'tmdb_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _episodeNumberMeta = const VerificationMeta('episodeNumber');
  @override
  late final GeneratedColumn<int> episodeNumber = GeneratedColumn<int>(
    'episode_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _airDateMeta = const VerificationMeta('airDate');
  @override
  late final GeneratedColumn<DateTime> airDate = GeneratedColumn<DateTime>(
    'air_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overviewMeta = const VerificationMeta('overview');
  @override
  late final GeneratedColumn<String> overview = GeneratedColumn<String>(
    'overview',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stillUrlMeta = const VerificationMeta('stillUrl');
  @override
  late final GeneratedColumn<String> stillUrl = GeneratedColumn<String>(
    'still_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<Artist>, String> guestStars = GeneratedColumn<String>(
    'guest_stars',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<List<Artist>>($EpisodesTable.$converterguestStars);
  @override
  List<GeneratedColumn> get $columns => [tmdbId, episodeNumber, title, airDate, overview, stillUrl, guestStars];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'episodes';
  @override
  VerificationContext validateIntegrity(Insertable<Episode> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tmdb_id')) {
      context.handle(_tmdbIdMeta, tmdbId.isAcceptableOrUnknown(data['tmdb_id']!, _tmdbIdMeta));
    } else if (isInserting) {
      context.missing(_tmdbIdMeta);
    }
    if (data.containsKey('episode_number')) {
      context.handle(
        _episodeNumberMeta,
        episodeNumber.isAcceptableOrUnknown(data['episode_number']!, _episodeNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_episodeNumberMeta);
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('air_date')) {
      context.handle(_airDateMeta, airDate.isAcceptableOrUnknown(data['air_date']!, _airDateMeta));
    }
    if (data.containsKey('overview')) {
      context.handle(_overviewMeta, overview.isAcceptableOrUnknown(data['overview']!, _overviewMeta));
    }
    if (data.containsKey('still_url')) {
      context.handle(_stillUrlMeta, stillUrl.isAcceptableOrUnknown(data['still_url']!, _stillUrlMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tmdbId};
  @override
  Episode map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Episode(
      tmdbId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}tmdb_id'])!,
      episodeNumber: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}episode_number'])!,
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      airDate: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}air_date']),
      overview: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}overview']),
      stillUrl: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}still_url']),
      guestStars: $EpisodesTable.$converterguestStars.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}guest_stars'])!,
      ),
    );
  }

  @override
  $EpisodesTable createAlias(String alias) {
    return $EpisodesTable(attachedDatabase, alias);
  }

  static TypeConverter<List<Artist>, String> $converterguestStars = const ArtistListConverter();
}

class EpisodesCompanion extends UpdateCompanion<Episode> {
  final Value<String> tmdbId;
  final Value<int> episodeNumber;
  final Value<String> title;
  final Value<DateTime?> airDate;
  final Value<String?> overview;
  final Value<String?> stillUrl;
  final Value<List<Artist>> guestStars;
  final Value<int> rowid;
  const EpisodesCompanion({
    this.tmdbId = const Value.absent(),
    this.episodeNumber = const Value.absent(),
    this.title = const Value.absent(),
    this.airDate = const Value.absent(),
    this.overview = const Value.absent(),
    this.stillUrl = const Value.absent(),
    this.guestStars = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EpisodesCompanion.insert({
    required String tmdbId,
    required int episodeNumber,
    required String title,
    this.airDate = const Value.absent(),
    this.overview = const Value.absent(),
    this.stillUrl = const Value.absent(),
    required List<Artist> guestStars,
    this.rowid = const Value.absent(),
  }) : tmdbId = Value(tmdbId),
       episodeNumber = Value(episodeNumber),
       title = Value(title),
       guestStars = Value(guestStars);
  static Insertable<Episode> custom({
    Expression<String>? tmdbId,
    Expression<int>? episodeNumber,
    Expression<String>? title,
    Expression<DateTime>? airDate,
    Expression<String>? overview,
    Expression<String>? stillUrl,
    Expression<String>? guestStars,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tmdbId != null) 'tmdb_id': tmdbId,
      if (episodeNumber != null) 'episode_number': episodeNumber,
      if (title != null) 'title': title,
      if (airDate != null) 'air_date': airDate,
      if (overview != null) 'overview': overview,
      if (stillUrl != null) 'still_url': stillUrl,
      if (guestStars != null) 'guest_stars': guestStars,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EpisodesCompanion copyWith({
    Value<String>? tmdbId,
    Value<int>? episodeNumber,
    Value<String>? title,
    Value<DateTime?>? airDate,
    Value<String?>? overview,
    Value<String?>? stillUrl,
    Value<List<Artist>>? guestStars,
    Value<int>? rowid,
  }) {
    return EpisodesCompanion(
      tmdbId: tmdbId ?? this.tmdbId,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      title: title ?? this.title,
      airDate: airDate ?? this.airDate,
      overview: overview ?? this.overview,
      stillUrl: stillUrl ?? this.stillUrl,
      guestStars: guestStars ?? this.guestStars,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tmdbId.present) {
      map['tmdb_id'] = Variable<String>(tmdbId.value);
    }
    if (episodeNumber.present) {
      map['episode_number'] = Variable<int>(episodeNumber.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (airDate.present) {
      map['air_date'] = Variable<DateTime>(airDate.value);
    }
    if (overview.present) {
      map['overview'] = Variable<String>(overview.value);
    }
    if (stillUrl.present) {
      map['still_url'] = Variable<String>(stillUrl.value);
    }
    if (guestStars.present) {
      map['guest_stars'] = Variable<String>($EpisodesTable.$converterguestStars.toSql(guestStars.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EpisodesCompanion(')
          ..write('tmdbId: $tmdbId, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('title: $title, ')
          ..write('airDate: $airDate, ')
          ..write('overview: $overview, ')
          ..write('stillUrl: $stillUrl, ')
          ..write('guestStars: $guestStars, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class _$EpisodeInsertable implements Insertable<Episode> {
  Episode _object;
  _$EpisodeInsertable(this._object);
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    return EpisodesCompanion(
      tmdbId: Value(_object.tmdbId),
      episodeNumber: Value(_object.episodeNumber),
      title: Value(_object.title),
      airDate: Value(_object.airDate),
      overview: Value(_object.overview),
      stillUrl: Value(_object.stillUrl),
      guestStars: Value(_object.guestStars),
    ).toColumns(false);
  }
}

extension EpisodeToInsertable on Episode {
  _$EpisodeInsertable toInsertable() {
    return _$EpisodeInsertable(this);
  }
}

class $StorageSourcesTable extends StorageSources with TableInfo<$StorageSourcesTable, StorageSourceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StorageSourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta('sourceId');
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endpointMeta = const VerificationMeta('endpoint');
  @override
  late final GeneratedColumn<String> endpoint = GeneratedColumn<String>(
    'endpoint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rootPathMeta = const VerificationMeta('rootPath');
  @override
  late final GeneratedColumn<String> rootPath = GeneratedColumn<String>(
    'root_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta('enabled');
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("enabled" IN (0, 1))'),
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta('username');
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _passwordMeta = const VerificationMeta('password');
  @override
  late final GeneratedColumn<String> password = GeneratedColumn<String>(
    'password',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, sourceId, name, type, endpoint, rootPath, enabled, username, password];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'storage_sources';
  @override
  VerificationContext validateIntegrity(Insertable<StorageSourceRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source_id')) {
      context.handle(_sourceIdMeta, sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta));
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(_typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('endpoint')) {
      context.handle(_endpointMeta, endpoint.isAcceptableOrUnknown(data['endpoint']!, _endpointMeta));
    } else if (isInserting) {
      context.missing(_endpointMeta);
    }
    if (data.containsKey('root_path')) {
      context.handle(_rootPathMeta, rootPath.isAcceptableOrUnknown(data['root_path']!, _rootPathMeta));
    } else if (isInserting) {
      context.missing(_rootPathMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(_enabledMeta, enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta));
    } else if (isInserting) {
      context.missing(_enabledMeta);
    }
    if (data.containsKey('username')) {
      context.handle(_usernameMeta, username.isAcceptableOrUnknown(data['username']!, _usernameMeta));
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('password')) {
      context.handle(_passwordMeta, password.isAcceptableOrUnknown(data['password']!, _passwordMeta));
    } else if (isInserting) {
      context.missing(_passwordMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StorageSourceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StorageSourceRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      sourceId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}source_id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      endpoint: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}endpoint'])!,
      rootPath: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}root_path'])!,
      enabled: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}enabled'])!,
      username: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}username'])!,
      password: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}password'])!,
    );
  }

  @override
  $StorageSourcesTable createAlias(String alias) {
    return $StorageSourcesTable(attachedDatabase, alias);
  }
}

class StorageSourceRow extends DataClass implements Insertable<StorageSourceRow> {
  final int id;
  final String sourceId;
  final String name;
  final String type;
  final String endpoint;
  final String rootPath;
  final bool enabled;
  final String username;
  final String password;
  const StorageSourceRow({
    required this.id,
    required this.sourceId,
    required this.name,
    required this.type,
    required this.endpoint,
    required this.rootPath,
    required this.enabled,
    required this.username,
    required this.password,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['source_id'] = Variable<String>(sourceId);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['endpoint'] = Variable<String>(endpoint);
    map['root_path'] = Variable<String>(rootPath);
    map['enabled'] = Variable<bool>(enabled);
    map['username'] = Variable<String>(username);
    map['password'] = Variable<String>(password);
    return map;
  }

  StorageSourcesCompanion toCompanion(bool nullToAbsent) {
    return StorageSourcesCompanion(
      id: Value(id),
      sourceId: Value(sourceId),
      name: Value(name),
      type: Value(type),
      endpoint: Value(endpoint),
      rootPath: Value(rootPath),
      enabled: Value(enabled),
      username: Value(username),
      password: Value(password),
    );
  }

  factory StorageSourceRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StorageSourceRow(
      id: serializer.fromJson<int>(json['id']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      endpoint: serializer.fromJson<String>(json['endpoint']),
      rootPath: serializer.fromJson<String>(json['rootPath']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      username: serializer.fromJson<String>(json['username']),
      password: serializer.fromJson<String>(json['password']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sourceId': serializer.toJson<String>(sourceId),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'endpoint': serializer.toJson<String>(endpoint),
      'rootPath': serializer.toJson<String>(rootPath),
      'enabled': serializer.toJson<bool>(enabled),
      'username': serializer.toJson<String>(username),
      'password': serializer.toJson<String>(password),
    };
  }

  StorageSourceRow copyWith({
    int? id,
    String? sourceId,
    String? name,
    String? type,
    String? endpoint,
    String? rootPath,
    bool? enabled,
    String? username,
    String? password,
  }) => StorageSourceRow(
    id: id ?? this.id,
    sourceId: sourceId ?? this.sourceId,
    name: name ?? this.name,
    type: type ?? this.type,
    endpoint: endpoint ?? this.endpoint,
    rootPath: rootPath ?? this.rootPath,
    enabled: enabled ?? this.enabled,
    username: username ?? this.username,
    password: password ?? this.password,
  );
  StorageSourceRow copyWithCompanion(StorageSourcesCompanion data) {
    return StorageSourceRow(
      id: data.id.present ? data.id.value : this.id,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      endpoint: data.endpoint.present ? data.endpoint.value : this.endpoint,
      rootPath: data.rootPath.present ? data.rootPath.value : this.rootPath,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      username: data.username.present ? data.username.value : this.username,
      password: data.password.present ? data.password.value : this.password,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StorageSourceRow(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('endpoint: $endpoint, ')
          ..write('rootPath: $rootPath, ')
          ..write('enabled: $enabled, ')
          ..write('username: $username, ')
          ..write('password: $password')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sourceId, name, type, endpoint, rootPath, enabled, username, password);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StorageSourceRow &&
          other.id == this.id &&
          other.sourceId == this.sourceId &&
          other.name == this.name &&
          other.type == this.type &&
          other.endpoint == this.endpoint &&
          other.rootPath == this.rootPath &&
          other.enabled == this.enabled &&
          other.username == this.username &&
          other.password == this.password);
}

class StorageSourcesCompanion extends UpdateCompanion<StorageSourceRow> {
  final Value<int> id;
  final Value<String> sourceId;
  final Value<String> name;
  final Value<String> type;
  final Value<String> endpoint;
  final Value<String> rootPath;
  final Value<bool> enabled;
  final Value<String> username;
  final Value<String> password;
  const StorageSourcesCompanion({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.endpoint = const Value.absent(),
    this.rootPath = const Value.absent(),
    this.enabled = const Value.absent(),
    this.username = const Value.absent(),
    this.password = const Value.absent(),
  });
  StorageSourcesCompanion.insert({
    this.id = const Value.absent(),
    required String sourceId,
    required String name,
    required String type,
    required String endpoint,
    required String rootPath,
    required bool enabled,
    required String username,
    required String password,
  }) : sourceId = Value(sourceId),
       name = Value(name),
       type = Value(type),
       endpoint = Value(endpoint),
       rootPath = Value(rootPath),
       enabled = Value(enabled),
       username = Value(username),
       password = Value(password);
  static Insertable<StorageSourceRow> custom({
    Expression<int>? id,
    Expression<String>? sourceId,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? endpoint,
    Expression<String>? rootPath,
    Expression<bool>? enabled,
    Expression<String>? username,
    Expression<String>? password,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceId != null) 'source_id': sourceId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (endpoint != null) 'endpoint': endpoint,
      if (rootPath != null) 'root_path': rootPath,
      if (enabled != null) 'enabled': enabled,
      if (username != null) 'username': username,
      if (password != null) 'password': password,
    });
  }

  StorageSourcesCompanion copyWith({
    Value<int>? id,
    Value<String>? sourceId,
    Value<String>? name,
    Value<String>? type,
    Value<String>? endpoint,
    Value<String>? rootPath,
    Value<bool>? enabled,
    Value<String>? username,
    Value<String>? password,
  }) {
    return StorageSourcesCompanion(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      name: name ?? this.name,
      type: type ?? this.type,
      endpoint: endpoint ?? this.endpoint,
      rootPath: rootPath ?? this.rootPath,
      enabled: enabled ?? this.enabled,
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (endpoint.present) {
      map['endpoint'] = Variable<String>(endpoint.value);
    }
    if (rootPath.present) {
      map['root_path'] = Variable<String>(rootPath.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (password.present) {
      map['password'] = Variable<String>(password.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StorageSourcesCompanion(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('endpoint: $endpoint, ')
          ..write('rootPath: $rootPath, ')
          ..write('enabled: $enabled, ')
          ..write('username: $username, ')
          ..write('password: $password')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MediaFilesTable mediaFiles = $MediaFilesTable(this);
  late final $MoviesTable movies = $MoviesTable(this);
  late final $TVShowsTable tVShows = $TVShowsTable(this);
  late final $SeasonsTable seasons = $SeasonsTable(this);
  late final $EpisodesTable episodes = $EpisodesTable(this);
  late final $StorageSourcesTable storageSources = $StorageSourcesTable(this);
  late final Index mediaFilesSourceIdIdx = Index(
    'media_files_source_id_idx',
    'CREATE INDEX media_files_source_id_idx ON media_files (source_id)',
  );
  late final Index mediaFilesExplicitTmdbIdIdx = Index(
    'media_files_explicit_tmdb_id_idx',
    'CREATE INDEX media_files_explicit_tmdb_id_idx ON media_files (explicit_tmdb_id)',
  );
  late final Index mediaFilesMovieTmdbIdIdx = Index(
    'media_files_movie_tmdb_id_idx',
    'CREATE INDEX media_files_movie_tmdb_id_idx ON media_files (movie_tmdb_id)',
  );
  late final Index mediaFilesTvShowTmdbIdIdx = Index(
    'media_files_tv_show_tmdb_id_idx',
    'CREATE INDEX media_files_tv_show_tmdb_id_idx ON media_files (tv_show_tmdb_id)',
  );
  late final Index mediaFilesEpisodeTmdbIdIdx = Index(
    'media_files_episode_tmdb_id_idx',
    'CREATE INDEX media_files_episode_tmdb_id_idx ON media_files (episode_tmdb_id)',
  );
  late final Index mediaFilesWatchStatusIdx = Index(
    'media_files_watch_status_idx',
    'CREATE INDEX media_files_watch_status_idx ON media_files (watch_status)',
  );
  late final Index mediaFilesLastWatchedAtIdx = Index(
    'media_files_last_watched_at_idx',
    'CREATE INDEX media_files_last_watched_at_idx ON media_files (last_watched_at)',
  );
  late final Index mediaFilesIsFavoriteIdx = Index(
    'media_files_is_favorite_idx',
    'CREATE INDEX media_files_is_favorite_idx ON media_files (is_favorite)',
  );
  late final Index mediaFilesAddedAtIdx = Index(
    'media_files_added_at_idx',
    'CREATE INDEX media_files_added_at_idx ON media_files (added_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    mediaFiles,
    movies,
    tVShows,
    seasons,
    episodes,
    storageSources,
    mediaFilesSourceIdIdx,
    mediaFilesExplicitTmdbIdIdx,
    mediaFilesMovieTmdbIdIdx,
    mediaFilesTvShowTmdbIdIdx,
    mediaFilesEpisodeTmdbIdIdx,
    mediaFilesWatchStatusIdx,
    mediaFilesLastWatchedAtIdx,
    mediaFilesIsFavoriteIdx,
    mediaFilesAddedAtIdx,
  ];
  @override
  DriftDatabaseOptions get options => const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$MediaFilesTableCreateCompanionBuilder =
    MediaFilesCompanion Function({
      Value<int> id,
      required String sourceId,
      required String storageKey,
      required String path,
      required String fileName,
      required String parsedTitle,
      Value<int?> parsedYear,
      Value<int?> parsedSeason,
      Value<int?> parsedEpisode,
      required MediaType mediaType,
      Value<String?> explicitTmdbId,
      Value<String?> movieTmdbId,
      Value<String?> tvShowTmdbId,
      Value<String?> episodeTmdbId,
      required MetadataMatchStatus metadataMatchStatus,
      required int size,
      Value<String?> container,
      Value<int?> width,
      Value<int?> height,
      Value<String?> videoCodec,
      Value<String?> audioCodec,
      Value<String?> audioChannels,
      required bool isHdr,
      Value<String?> hdrFormat,
      Value<String?> versionLabel,
      required int duration,
      required int position,
      required WatchStatus watchStatus,
      Value<DateTime?> lastWatchedAt,
      required bool isFavorite,
      required DateTime addedAt,
    });
typedef $$MediaFilesTableUpdateCompanionBuilder =
    MediaFilesCompanion Function({
      Value<int> id,
      Value<String> sourceId,
      Value<String> storageKey,
      Value<String> path,
      Value<String> fileName,
      Value<String> parsedTitle,
      Value<int?> parsedYear,
      Value<int?> parsedSeason,
      Value<int?> parsedEpisode,
      Value<MediaType> mediaType,
      Value<String?> explicitTmdbId,
      Value<String?> movieTmdbId,
      Value<String?> tvShowTmdbId,
      Value<String?> episodeTmdbId,
      Value<MetadataMatchStatus> metadataMatchStatus,
      Value<int> size,
      Value<String?> container,
      Value<int?> width,
      Value<int?> height,
      Value<String?> videoCodec,
      Value<String?> audioCodec,
      Value<String?> audioChannels,
      Value<bool> isHdr,
      Value<String?> hdrFormat,
      Value<String?> versionLabel,
      Value<int> duration,
      Value<int> position,
      Value<WatchStatus> watchStatus,
      Value<DateTime?> lastWatchedAt,
      Value<bool> isFavorite,
      Value<DateTime> addedAt,
    });

class $$MediaFilesTableFilterComposer extends Composer<_$AppDatabase, $MediaFilesTable> {
  $$MediaFilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get storageKey =>
      $composableBuilder(column: $table.storageKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get path => $composableBuilder(column: $table.path, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parsedTitle =>
      $composableBuilder(column: $table.parsedTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get parsedYear =>
      $composableBuilder(column: $table.parsedYear, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get parsedSeason =>
      $composableBuilder(column: $table.parsedSeason, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get parsedEpisode =>
      $composableBuilder(column: $table.parsedEpisode, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<MediaType, MediaType, String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get explicitTmdbId =>
      $composableBuilder(column: $table.explicitTmdbId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get movieTmdbId =>
      $composableBuilder(column: $table.movieTmdbId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tvShowTmdbId =>
      $composableBuilder(column: $table.tvShowTmdbId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get episodeTmdbId =>
      $composableBuilder(column: $table.episodeTmdbId, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<MetadataMatchStatus, MetadataMatchStatus, String> get metadataMatchStatus =>
      $composableBuilder(
        column: $table.metadataMatchStatus,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get size => $composableBuilder(column: $table.size, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get container =>
      $composableBuilder(column: $table.container, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get width => $composableBuilder(column: $table.width, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get videoCodec =>
      $composableBuilder(column: $table.videoCodec, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get audioCodec =>
      $composableBuilder(column: $table.audioCodec, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get audioChannels =>
      $composableBuilder(column: $table.audioChannels, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isHdr => $composableBuilder(column: $table.isHdr, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hdrFormat =>
      $composableBuilder(column: $table.hdrFormat, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get versionLabel =>
      $composableBuilder(column: $table.versionLabel, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<WatchStatus, WatchStatus, String> get watchStatus =>
      $composableBuilder(column: $table.watchStatus, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<DateTime> get lastWatchedAt =>
      $composableBuilder(column: $table.lastWatchedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFavorite =>
      $composableBuilder(column: $table.isFavorite, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => ColumnFilters(column));
}

class $$MediaFilesTableOrderingComposer extends Composer<_$AppDatabase, $MediaFilesTable> {
  $$MediaFilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get storageKey =>
      $composableBuilder(column: $table.storageKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parsedTitle =>
      $composableBuilder(column: $table.parsedTitle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get parsedYear =>
      $composableBuilder(column: $table.parsedYear, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get parsedSeason =>
      $composableBuilder(column: $table.parsedSeason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get parsedEpisode =>
      $composableBuilder(column: $table.parsedEpisode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get explicitTmdbId =>
      $composableBuilder(column: $table.explicitTmdbId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get movieTmdbId =>
      $composableBuilder(column: $table.movieTmdbId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tvShowTmdbId =>
      $composableBuilder(column: $table.tvShowTmdbId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get episodeTmdbId =>
      $composableBuilder(column: $table.episodeTmdbId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metadataMatchStatus =>
      $composableBuilder(column: $table.metadataMatchStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get container =>
      $composableBuilder(column: $table.container, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get videoCodec =>
      $composableBuilder(column: $table.videoCodec, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get audioCodec =>
      $composableBuilder(column: $table.audioCodec, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get audioChannels =>
      $composableBuilder(column: $table.audioChannels, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isHdr =>
      $composableBuilder(column: $table.isHdr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hdrFormat =>
      $composableBuilder(column: $table.hdrFormat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get versionLabel =>
      $composableBuilder(column: $table.versionLabel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get watchStatus =>
      $composableBuilder(column: $table.watchStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastWatchedAt =>
      $composableBuilder(column: $table.lastWatchedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFavorite =>
      $composableBuilder(column: $table.isFavorite, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => ColumnOrderings(column));
}

class $$MediaFilesTableAnnotationComposer extends Composer<_$AppDatabase, $MediaFilesTable> {
  $$MediaFilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceId => $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get storageKey => $composableBuilder(column: $table.storageKey, builder: (column) => column);

  GeneratedColumn<String> get path => $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get fileName => $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get parsedTitle =>
      $composableBuilder(column: $table.parsedTitle, builder: (column) => column);

  GeneratedColumn<int> get parsedYear => $composableBuilder(column: $table.parsedYear, builder: (column) => column);

  GeneratedColumn<int> get parsedSeason => $composableBuilder(column: $table.parsedSeason, builder: (column) => column);

  GeneratedColumn<int> get parsedEpisode =>
      $composableBuilder(column: $table.parsedEpisode, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MediaType, String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<String> get explicitTmdbId =>
      $composableBuilder(column: $table.explicitTmdbId, builder: (column) => column);

  GeneratedColumn<String> get movieTmdbId =>
      $composableBuilder(column: $table.movieTmdbId, builder: (column) => column);

  GeneratedColumn<String> get tvShowTmdbId =>
      $composableBuilder(column: $table.tvShowTmdbId, builder: (column) => column);

  GeneratedColumn<String> get episodeTmdbId =>
      $composableBuilder(column: $table.episodeTmdbId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MetadataMatchStatus, String> get metadataMatchStatus =>
      $composableBuilder(column: $table.metadataMatchStatus, builder: (column) => column);

  GeneratedColumn<int> get size => $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<String> get container => $composableBuilder(column: $table.container, builder: (column) => column);

  GeneratedColumn<int> get width => $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height => $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<String> get videoCodec => $composableBuilder(column: $table.videoCodec, builder: (column) => column);

  GeneratedColumn<String> get audioCodec => $composableBuilder(column: $table.audioCodec, builder: (column) => column);

  GeneratedColumn<String> get audioChannels =>
      $composableBuilder(column: $table.audioChannels, builder: (column) => column);

  GeneratedColumn<bool> get isHdr => $composableBuilder(column: $table.isHdr, builder: (column) => column);

  GeneratedColumn<String> get hdrFormat => $composableBuilder(column: $table.hdrFormat, builder: (column) => column);

  GeneratedColumn<String> get versionLabel =>
      $composableBuilder(column: $table.versionLabel, builder: (column) => column);

  GeneratedColumn<int> get duration => $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<int> get position => $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumnWithTypeConverter<WatchStatus, String> get watchStatus =>
      $composableBuilder(column: $table.watchStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get lastWatchedAt =>
      $composableBuilder(column: $table.lastWatchedAt, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(column: $table.isFavorite, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt => $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$MediaFilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MediaFilesTable,
          MediaFile,
          $$MediaFilesTableFilterComposer,
          $$MediaFilesTableOrderingComposer,
          $$MediaFilesTableAnnotationComposer,
          $$MediaFilesTableCreateCompanionBuilder,
          $$MediaFilesTableUpdateCompanionBuilder,
          (MediaFile, BaseReferences<_$AppDatabase, $MediaFilesTable, MediaFile>),
          MediaFile,
          PrefetchHooks Function()
        > {
  $$MediaFilesTableTableManager(_$AppDatabase db, $MediaFilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$MediaFilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$MediaFilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$MediaFilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String> storageKey = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<String> parsedTitle = const Value.absent(),
                Value<int?> parsedYear = const Value.absent(),
                Value<int?> parsedSeason = const Value.absent(),
                Value<int?> parsedEpisode = const Value.absent(),
                Value<MediaType> mediaType = const Value.absent(),
                Value<String?> explicitTmdbId = const Value.absent(),
                Value<String?> movieTmdbId = const Value.absent(),
                Value<String?> tvShowTmdbId = const Value.absent(),
                Value<String?> episodeTmdbId = const Value.absent(),
                Value<MetadataMatchStatus> metadataMatchStatus = const Value.absent(),
                Value<int> size = const Value.absent(),
                Value<String?> container = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<String?> videoCodec = const Value.absent(),
                Value<String?> audioCodec = const Value.absent(),
                Value<String?> audioChannels = const Value.absent(),
                Value<bool> isHdr = const Value.absent(),
                Value<String?> hdrFormat = const Value.absent(),
                Value<String?> versionLabel = const Value.absent(),
                Value<int> duration = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<WatchStatus> watchStatus = const Value.absent(),
                Value<DateTime?> lastWatchedAt = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
              }) => MediaFilesCompanion(
                id: id,
                sourceId: sourceId,
                storageKey: storageKey,
                path: path,
                fileName: fileName,
                parsedTitle: parsedTitle,
                parsedYear: parsedYear,
                parsedSeason: parsedSeason,
                parsedEpisode: parsedEpisode,
                mediaType: mediaType,
                explicitTmdbId: explicitTmdbId,
                movieTmdbId: movieTmdbId,
                tvShowTmdbId: tvShowTmdbId,
                episodeTmdbId: episodeTmdbId,
                metadataMatchStatus: metadataMatchStatus,
                size: size,
                container: container,
                width: width,
                height: height,
                videoCodec: videoCodec,
                audioCodec: audioCodec,
                audioChannels: audioChannels,
                isHdr: isHdr,
                hdrFormat: hdrFormat,
                versionLabel: versionLabel,
                duration: duration,
                position: position,
                watchStatus: watchStatus,
                lastWatchedAt: lastWatchedAt,
                isFavorite: isFavorite,
                addedAt: addedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sourceId,
                required String storageKey,
                required String path,
                required String fileName,
                required String parsedTitle,
                Value<int?> parsedYear = const Value.absent(),
                Value<int?> parsedSeason = const Value.absent(),
                Value<int?> parsedEpisode = const Value.absent(),
                required MediaType mediaType,
                Value<String?> explicitTmdbId = const Value.absent(),
                Value<String?> movieTmdbId = const Value.absent(),
                Value<String?> tvShowTmdbId = const Value.absent(),
                Value<String?> episodeTmdbId = const Value.absent(),
                required MetadataMatchStatus metadataMatchStatus,
                required int size,
                Value<String?> container = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<String?> videoCodec = const Value.absent(),
                Value<String?> audioCodec = const Value.absent(),
                Value<String?> audioChannels = const Value.absent(),
                required bool isHdr,
                Value<String?> hdrFormat = const Value.absent(),
                Value<String?> versionLabel = const Value.absent(),
                required int duration,
                required int position,
                required WatchStatus watchStatus,
                Value<DateTime?> lastWatchedAt = const Value.absent(),
                required bool isFavorite,
                required DateTime addedAt,
              }) => MediaFilesCompanion.insert(
                id: id,
                sourceId: sourceId,
                storageKey: storageKey,
                path: path,
                fileName: fileName,
                parsedTitle: parsedTitle,
                parsedYear: parsedYear,
                parsedSeason: parsedSeason,
                parsedEpisode: parsedEpisode,
                mediaType: mediaType,
                explicitTmdbId: explicitTmdbId,
                movieTmdbId: movieTmdbId,
                tvShowTmdbId: tvShowTmdbId,
                episodeTmdbId: episodeTmdbId,
                metadataMatchStatus: metadataMatchStatus,
                size: size,
                container: container,
                width: width,
                height: height,
                videoCodec: videoCodec,
                audioCodec: audioCodec,
                audioChannels: audioChannels,
                isHdr: isHdr,
                hdrFormat: hdrFormat,
                versionLabel: versionLabel,
                duration: duration,
                position: position,
                watchStatus: watchStatus,
                lastWatchedAt: lastWatchedAt,
                isFavorite: isFavorite,
                addedAt: addedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MediaFilesTable, MediaFile>(table),
                  BaseReferences<_$AppDatabase, $MediaFilesTable, MediaFile>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MediaFilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MediaFilesTable,
      MediaFile,
      $$MediaFilesTableFilterComposer,
      $$MediaFilesTableOrderingComposer,
      $$MediaFilesTableAnnotationComposer,
      $$MediaFilesTableCreateCompanionBuilder,
      $$MediaFilesTableUpdateCompanionBuilder,
      (MediaFile, BaseReferences<_$AppDatabase, $MediaFilesTable, MediaFile>),
      MediaFile,
      PrefetchHooks Function()
    >;
typedef $$MoviesTableCreateCompanionBuilder =
    MoviesCompanion Function({
      required String tmdbId,
      required String title,
      Value<String?> originalTitle,
      Value<int?> releaseYear,
      Value<DateTime?> releaseDate,
      Value<String?> posterUrl,
      Value<String?> backdropUrl,
      Value<String?> logoUrl,
      Value<String?> overview,
      Value<String?> certification,
      required double rating,
      required List<String> genres,
      required List<Artist> cast,
      Value<int> rowid,
    });
typedef $$MoviesTableUpdateCompanionBuilder =
    MoviesCompanion Function({
      Value<String> tmdbId,
      Value<String> title,
      Value<String?> originalTitle,
      Value<int?> releaseYear,
      Value<DateTime?> releaseDate,
      Value<String?> posterUrl,
      Value<String?> backdropUrl,
      Value<String?> logoUrl,
      Value<String?> overview,
      Value<String?> certification,
      Value<double> rating,
      Value<List<String>> genres,
      Value<List<Artist>> cast,
      Value<int> rowid,
    });

class $$MoviesTableFilterComposer extends Composer<_$AppDatabase, $MoviesTable> {
  $$MoviesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originalTitle =>
      $composableBuilder(column: $table.originalTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get releaseYear =>
      $composableBuilder(column: $table.releaseYear, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get releaseDate =>
      $composableBuilder(column: $table.releaseDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get posterUrl =>
      $composableBuilder(column: $table.posterUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get backdropUrl =>
      $composableBuilder(column: $table.backdropUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get logoUrl =>
      $composableBuilder(column: $table.logoUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get certification =>
      $composableBuilder(column: $table.certification, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<String>, List<String>, String> get genres =>
      $composableBuilder(column: $table.genres, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<List<Artist>, List<Artist>, String> get cast =>
      $composableBuilder(column: $table.cast, builder: (column) => ColumnWithTypeConverterFilters(column));
}

class $$MoviesTableOrderingComposer extends Composer<_$AppDatabase, $MoviesTable> {
  $$MoviesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originalTitle =>
      $composableBuilder(column: $table.originalTitle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get releaseYear =>
      $composableBuilder(column: $table.releaseYear, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get releaseDate =>
      $composableBuilder(column: $table.releaseDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get posterUrl =>
      $composableBuilder(column: $table.posterUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get backdropUrl =>
      $composableBuilder(column: $table.backdropUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get logoUrl =>
      $composableBuilder(column: $table.logoUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get certification =>
      $composableBuilder(column: $table.certification, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get genres =>
      $composableBuilder(column: $table.genres, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cast =>
      $composableBuilder(column: $table.cast, builder: (column) => ColumnOrderings(column));
}

class $$MoviesTableAnnotationComposer extends Composer<_$AppDatabase, $MoviesTable> {
  $$MoviesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tmdbId => $composableBuilder(column: $table.tmdbId, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get originalTitle =>
      $composableBuilder(column: $table.originalTitle, builder: (column) => column);

  GeneratedColumn<int> get releaseYear => $composableBuilder(column: $table.releaseYear, builder: (column) => column);

  GeneratedColumn<DateTime> get releaseDate =>
      $composableBuilder(column: $table.releaseDate, builder: (column) => column);

  GeneratedColumn<String> get posterUrl => $composableBuilder(column: $table.posterUrl, builder: (column) => column);

  GeneratedColumn<String> get backdropUrl =>
      $composableBuilder(column: $table.backdropUrl, builder: (column) => column);

  GeneratedColumn<String> get logoUrl => $composableBuilder(column: $table.logoUrl, builder: (column) => column);

  GeneratedColumn<String> get overview => $composableBuilder(column: $table.overview, builder: (column) => column);

  GeneratedColumn<String> get certification =>
      $composableBuilder(column: $table.certification, builder: (column) => column);

  GeneratedColumn<double> get rating => $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get genres =>
      $composableBuilder(column: $table.genres, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<Artist>, String> get cast =>
      $composableBuilder(column: $table.cast, builder: (column) => column);
}

class $$MoviesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MoviesTable,
          Movie,
          $$MoviesTableFilterComposer,
          $$MoviesTableOrderingComposer,
          $$MoviesTableAnnotationComposer,
          $$MoviesTableCreateCompanionBuilder,
          $$MoviesTableUpdateCompanionBuilder,
          (Movie, BaseReferences<_$AppDatabase, $MoviesTable, Movie>),
          Movie,
          PrefetchHooks Function()
        > {
  $$MoviesTableTableManager(_$AppDatabase db, $MoviesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$MoviesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$MoviesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$MoviesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tmdbId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> originalTitle = const Value.absent(),
                Value<int?> releaseYear = const Value.absent(),
                Value<DateTime?> releaseDate = const Value.absent(),
                Value<String?> posterUrl = const Value.absent(),
                Value<String?> backdropUrl = const Value.absent(),
                Value<String?> logoUrl = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<String?> certification = const Value.absent(),
                Value<double> rating = const Value.absent(),
                Value<List<String>> genres = const Value.absent(),
                Value<List<Artist>> cast = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MoviesCompanion(
                tmdbId: tmdbId,
                title: title,
                originalTitle: originalTitle,
                releaseYear: releaseYear,
                releaseDate: releaseDate,
                posterUrl: posterUrl,
                backdropUrl: backdropUrl,
                logoUrl: logoUrl,
                overview: overview,
                certification: certification,
                rating: rating,
                genres: genres,
                cast: cast,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tmdbId,
                required String title,
                Value<String?> originalTitle = const Value.absent(),
                Value<int?> releaseYear = const Value.absent(),
                Value<DateTime?> releaseDate = const Value.absent(),
                Value<String?> posterUrl = const Value.absent(),
                Value<String?> backdropUrl = const Value.absent(),
                Value<String?> logoUrl = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<String?> certification = const Value.absent(),
                required double rating,
                required List<String> genres,
                required List<Artist> cast,
                Value<int> rowid = const Value.absent(),
              }) => MoviesCompanion.insert(
                tmdbId: tmdbId,
                title: title,
                originalTitle: originalTitle,
                releaseYear: releaseYear,
                releaseDate: releaseDate,
                posterUrl: posterUrl,
                backdropUrl: backdropUrl,
                logoUrl: logoUrl,
                overview: overview,
                certification: certification,
                rating: rating,
                genres: genres,
                cast: cast,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MoviesTable, Movie>(table),
                  BaseReferences<_$AppDatabase, $MoviesTable, Movie>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MoviesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MoviesTable,
      Movie,
      $$MoviesTableFilterComposer,
      $$MoviesTableOrderingComposer,
      $$MoviesTableAnnotationComposer,
      $$MoviesTableCreateCompanionBuilder,
      $$MoviesTableUpdateCompanionBuilder,
      (Movie, BaseReferences<_$AppDatabase, $MoviesTable, Movie>),
      Movie,
      PrefetchHooks Function()
    >;
typedef $$TVShowsTableCreateCompanionBuilder =
    TVShowsCompanion Function({
      required String tmdbId,
      required String title,
      Value<String?> originalTitle,
      Value<int?> releaseYear,
      Value<DateTime?> firstAirDate,
      Value<String?> posterUrl,
      Value<String?> backdropUrl,
      Value<String?> logoUrl,
      Value<String?> overview,
      Value<String?> certification,
      required double rating,
      required List<String> genres,
      required List<Artist> cast,
      Value<String?> status,
      Value<int?> numberOfSeasons,
      Value<int?> numberOfEpisodes,
      Value<int> rowid,
    });
typedef $$TVShowsTableUpdateCompanionBuilder =
    TVShowsCompanion Function({
      Value<String> tmdbId,
      Value<String> title,
      Value<String?> originalTitle,
      Value<int?> releaseYear,
      Value<DateTime?> firstAirDate,
      Value<String?> posterUrl,
      Value<String?> backdropUrl,
      Value<String?> logoUrl,
      Value<String?> overview,
      Value<String?> certification,
      Value<double> rating,
      Value<List<String>> genres,
      Value<List<Artist>> cast,
      Value<String?> status,
      Value<int?> numberOfSeasons,
      Value<int?> numberOfEpisodes,
      Value<int> rowid,
    });

class $$TVShowsTableFilterComposer extends Composer<_$AppDatabase, $TVShowsTable> {
  $$TVShowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originalTitle =>
      $composableBuilder(column: $table.originalTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get releaseYear =>
      $composableBuilder(column: $table.releaseYear, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get firstAirDate =>
      $composableBuilder(column: $table.firstAirDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get posterUrl =>
      $composableBuilder(column: $table.posterUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get backdropUrl =>
      $composableBuilder(column: $table.backdropUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get logoUrl =>
      $composableBuilder(column: $table.logoUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get certification =>
      $composableBuilder(column: $table.certification, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<String>, List<String>, String> get genres =>
      $composableBuilder(column: $table.genres, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<List<Artist>, List<Artist>, String> get cast =>
      $composableBuilder(column: $table.cast, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get numberOfSeasons =>
      $composableBuilder(column: $table.numberOfSeasons, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get numberOfEpisodes =>
      $composableBuilder(column: $table.numberOfEpisodes, builder: (column) => ColumnFilters(column));
}

class $$TVShowsTableOrderingComposer extends Composer<_$AppDatabase, $TVShowsTable> {
  $$TVShowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originalTitle =>
      $composableBuilder(column: $table.originalTitle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get releaseYear =>
      $composableBuilder(column: $table.releaseYear, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get firstAirDate =>
      $composableBuilder(column: $table.firstAirDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get posterUrl =>
      $composableBuilder(column: $table.posterUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get backdropUrl =>
      $composableBuilder(column: $table.backdropUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get logoUrl =>
      $composableBuilder(column: $table.logoUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get certification =>
      $composableBuilder(column: $table.certification, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get genres =>
      $composableBuilder(column: $table.genres, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cast =>
      $composableBuilder(column: $table.cast, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get numberOfSeasons =>
      $composableBuilder(column: $table.numberOfSeasons, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get numberOfEpisodes =>
      $composableBuilder(column: $table.numberOfEpisodes, builder: (column) => ColumnOrderings(column));
}

class $$TVShowsTableAnnotationComposer extends Composer<_$AppDatabase, $TVShowsTable> {
  $$TVShowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tmdbId => $composableBuilder(column: $table.tmdbId, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get originalTitle =>
      $composableBuilder(column: $table.originalTitle, builder: (column) => column);

  GeneratedColumn<int> get releaseYear => $composableBuilder(column: $table.releaseYear, builder: (column) => column);

  GeneratedColumn<DateTime> get firstAirDate =>
      $composableBuilder(column: $table.firstAirDate, builder: (column) => column);

  GeneratedColumn<String> get posterUrl => $composableBuilder(column: $table.posterUrl, builder: (column) => column);

  GeneratedColumn<String> get backdropUrl =>
      $composableBuilder(column: $table.backdropUrl, builder: (column) => column);

  GeneratedColumn<String> get logoUrl => $composableBuilder(column: $table.logoUrl, builder: (column) => column);

  GeneratedColumn<String> get overview => $composableBuilder(column: $table.overview, builder: (column) => column);

  GeneratedColumn<String> get certification =>
      $composableBuilder(column: $table.certification, builder: (column) => column);

  GeneratedColumn<double> get rating => $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get genres =>
      $composableBuilder(column: $table.genres, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<Artist>, String> get cast =>
      $composableBuilder(column: $table.cast, builder: (column) => column);

  GeneratedColumn<String> get status => $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get numberOfSeasons =>
      $composableBuilder(column: $table.numberOfSeasons, builder: (column) => column);

  GeneratedColumn<int> get numberOfEpisodes =>
      $composableBuilder(column: $table.numberOfEpisodes, builder: (column) => column);
}

class $$TVShowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TVShowsTable,
          TVShow,
          $$TVShowsTableFilterComposer,
          $$TVShowsTableOrderingComposer,
          $$TVShowsTableAnnotationComposer,
          $$TVShowsTableCreateCompanionBuilder,
          $$TVShowsTableUpdateCompanionBuilder,
          (TVShow, BaseReferences<_$AppDatabase, $TVShowsTable, TVShow>),
          TVShow,
          PrefetchHooks Function()
        > {
  $$TVShowsTableTableManager(_$AppDatabase db, $TVShowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$TVShowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$TVShowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$TVShowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tmdbId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> originalTitle = const Value.absent(),
                Value<int?> releaseYear = const Value.absent(),
                Value<DateTime?> firstAirDate = const Value.absent(),
                Value<String?> posterUrl = const Value.absent(),
                Value<String?> backdropUrl = const Value.absent(),
                Value<String?> logoUrl = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<String?> certification = const Value.absent(),
                Value<double> rating = const Value.absent(),
                Value<List<String>> genres = const Value.absent(),
                Value<List<Artist>> cast = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<int?> numberOfSeasons = const Value.absent(),
                Value<int?> numberOfEpisodes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TVShowsCompanion(
                tmdbId: tmdbId,
                title: title,
                originalTitle: originalTitle,
                releaseYear: releaseYear,
                firstAirDate: firstAirDate,
                posterUrl: posterUrl,
                backdropUrl: backdropUrl,
                logoUrl: logoUrl,
                overview: overview,
                certification: certification,
                rating: rating,
                genres: genres,
                cast: cast,
                status: status,
                numberOfSeasons: numberOfSeasons,
                numberOfEpisodes: numberOfEpisodes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tmdbId,
                required String title,
                Value<String?> originalTitle = const Value.absent(),
                Value<int?> releaseYear = const Value.absent(),
                Value<DateTime?> firstAirDate = const Value.absent(),
                Value<String?> posterUrl = const Value.absent(),
                Value<String?> backdropUrl = const Value.absent(),
                Value<String?> logoUrl = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<String?> certification = const Value.absent(),
                required double rating,
                required List<String> genres,
                required List<Artist> cast,
                Value<String?> status = const Value.absent(),
                Value<int?> numberOfSeasons = const Value.absent(),
                Value<int?> numberOfEpisodes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TVShowsCompanion.insert(
                tmdbId: tmdbId,
                title: title,
                originalTitle: originalTitle,
                releaseYear: releaseYear,
                firstAirDate: firstAirDate,
                posterUrl: posterUrl,
                backdropUrl: backdropUrl,
                logoUrl: logoUrl,
                overview: overview,
                certification: certification,
                rating: rating,
                genres: genres,
                cast: cast,
                status: status,
                numberOfSeasons: numberOfSeasons,
                numberOfEpisodes: numberOfEpisodes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TVShowsTable, TVShow>(table),
                  BaseReferences<_$AppDatabase, $TVShowsTable, TVShow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TVShowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TVShowsTable,
      TVShow,
      $$TVShowsTableFilterComposer,
      $$TVShowsTableOrderingComposer,
      $$TVShowsTableAnnotationComposer,
      $$TVShowsTableCreateCompanionBuilder,
      $$TVShowsTableUpdateCompanionBuilder,
      (TVShow, BaseReferences<_$AppDatabase, $TVShowsTable, TVShow>),
      TVShow,
      PrefetchHooks Function()
    >;
typedef $$SeasonsTableCreateCompanionBuilder =
    SeasonsCompanion Function({
      required String seasonKey,
      required int seasonNumber,
      required String title,
      Value<String?> posterUrl,
      Value<String?> overview,
      Value<int?> numberOfEpisodes,
      Value<int> rowid,
    });
typedef $$SeasonsTableUpdateCompanionBuilder =
    SeasonsCompanion Function({
      Value<String> seasonKey,
      Value<int> seasonNumber,
      Value<String> title,
      Value<String?> posterUrl,
      Value<String?> overview,
      Value<int?> numberOfEpisodes,
      Value<int> rowid,
    });

class $$SeasonsTableFilterComposer extends Composer<_$AppDatabase, $SeasonsTable> {
  $$SeasonsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get seasonKey =>
      $composableBuilder(column: $table.seasonKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get seasonNumber =>
      $composableBuilder(column: $table.seasonNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get posterUrl =>
      $composableBuilder(column: $table.posterUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get numberOfEpisodes =>
      $composableBuilder(column: $table.numberOfEpisodes, builder: (column) => ColumnFilters(column));
}

class $$SeasonsTableOrderingComposer extends Composer<_$AppDatabase, $SeasonsTable> {
  $$SeasonsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get seasonKey =>
      $composableBuilder(column: $table.seasonKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get seasonNumber =>
      $composableBuilder(column: $table.seasonNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get posterUrl =>
      $composableBuilder(column: $table.posterUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get numberOfEpisodes =>
      $composableBuilder(column: $table.numberOfEpisodes, builder: (column) => ColumnOrderings(column));
}

class $$SeasonsTableAnnotationComposer extends Composer<_$AppDatabase, $SeasonsTable> {
  $$SeasonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get seasonKey => $composableBuilder(column: $table.seasonKey, builder: (column) => column);

  GeneratedColumn<int> get seasonNumber => $composableBuilder(column: $table.seasonNumber, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get posterUrl => $composableBuilder(column: $table.posterUrl, builder: (column) => column);

  GeneratedColumn<String> get overview => $composableBuilder(column: $table.overview, builder: (column) => column);

  GeneratedColumn<int> get numberOfEpisodes =>
      $composableBuilder(column: $table.numberOfEpisodes, builder: (column) => column);
}

class $$SeasonsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SeasonsTable,
          Season,
          $$SeasonsTableFilterComposer,
          $$SeasonsTableOrderingComposer,
          $$SeasonsTableAnnotationComposer,
          $$SeasonsTableCreateCompanionBuilder,
          $$SeasonsTableUpdateCompanionBuilder,
          (Season, BaseReferences<_$AppDatabase, $SeasonsTable, Season>),
          Season,
          PrefetchHooks Function()
        > {
  $$SeasonsTableTableManager(_$AppDatabase db, $SeasonsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SeasonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SeasonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$SeasonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> seasonKey = const Value.absent(),
                Value<int> seasonNumber = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> posterUrl = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<int?> numberOfEpisodes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeasonsCompanion(
                seasonKey: seasonKey,
                seasonNumber: seasonNumber,
                title: title,
                posterUrl: posterUrl,
                overview: overview,
                numberOfEpisodes: numberOfEpisodes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String seasonKey,
                required int seasonNumber,
                required String title,
                Value<String?> posterUrl = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<int?> numberOfEpisodes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeasonsCompanion.insert(
                seasonKey: seasonKey,
                seasonNumber: seasonNumber,
                title: title,
                posterUrl: posterUrl,
                overview: overview,
                numberOfEpisodes: numberOfEpisodes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SeasonsTable, Season>(table),
                  BaseReferences<_$AppDatabase, $SeasonsTable, Season>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SeasonsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SeasonsTable,
      Season,
      $$SeasonsTableFilterComposer,
      $$SeasonsTableOrderingComposer,
      $$SeasonsTableAnnotationComposer,
      $$SeasonsTableCreateCompanionBuilder,
      $$SeasonsTableUpdateCompanionBuilder,
      (Season, BaseReferences<_$AppDatabase, $SeasonsTable, Season>),
      Season,
      PrefetchHooks Function()
    >;
typedef $$EpisodesTableCreateCompanionBuilder =
    EpisodesCompanion Function({
      required String tmdbId,
      required int episodeNumber,
      required String title,
      Value<DateTime?> airDate,
      Value<String?> overview,
      Value<String?> stillUrl,
      required List<Artist> guestStars,
      Value<int> rowid,
    });
typedef $$EpisodesTableUpdateCompanionBuilder =
    EpisodesCompanion Function({
      Value<String> tmdbId,
      Value<int> episodeNumber,
      Value<String> title,
      Value<DateTime?> airDate,
      Value<String?> overview,
      Value<String?> stillUrl,
      Value<List<Artist>> guestStars,
      Value<int> rowid,
    });

class $$EpisodesTableFilterComposer extends Composer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get episodeNumber =>
      $composableBuilder(column: $table.episodeNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get airDate =>
      $composableBuilder(column: $table.airDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get stillUrl =>
      $composableBuilder(column: $table.stillUrl, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<Artist>, List<Artist>, String> get guestStars =>
      $composableBuilder(column: $table.guestStars, builder: (column) => ColumnWithTypeConverterFilters(column));
}

class $$EpisodesTableOrderingComposer extends Composer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get episodeNumber =>
      $composableBuilder(column: $table.episodeNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get airDate =>
      $composableBuilder(column: $table.airDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get stillUrl =>
      $composableBuilder(column: $table.stillUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get guestStars =>
      $composableBuilder(column: $table.guestStars, builder: (column) => ColumnOrderings(column));
}

class $$EpisodesTableAnnotationComposer extends Composer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tmdbId => $composableBuilder(column: $table.tmdbId, builder: (column) => column);

  GeneratedColumn<int> get episodeNumber =>
      $composableBuilder(column: $table.episodeNumber, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get airDate => $composableBuilder(column: $table.airDate, builder: (column) => column);

  GeneratedColumn<String> get overview => $composableBuilder(column: $table.overview, builder: (column) => column);

  GeneratedColumn<String> get stillUrl => $composableBuilder(column: $table.stillUrl, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<Artist>, String> get guestStars =>
      $composableBuilder(column: $table.guestStars, builder: (column) => column);
}

class $$EpisodesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EpisodesTable,
          Episode,
          $$EpisodesTableFilterComposer,
          $$EpisodesTableOrderingComposer,
          $$EpisodesTableAnnotationComposer,
          $$EpisodesTableCreateCompanionBuilder,
          $$EpisodesTableUpdateCompanionBuilder,
          (Episode, BaseReferences<_$AppDatabase, $EpisodesTable, Episode>),
          Episode,
          PrefetchHooks Function()
        > {
  $$EpisodesTableTableManager(_$AppDatabase db, $EpisodesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$EpisodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$EpisodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$EpisodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tmdbId = const Value.absent(),
                Value<int> episodeNumber = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<DateTime?> airDate = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<String?> stillUrl = const Value.absent(),
                Value<List<Artist>> guestStars = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EpisodesCompanion(
                tmdbId: tmdbId,
                episodeNumber: episodeNumber,
                title: title,
                airDate: airDate,
                overview: overview,
                stillUrl: stillUrl,
                guestStars: guestStars,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tmdbId,
                required int episodeNumber,
                required String title,
                Value<DateTime?> airDate = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<String?> stillUrl = const Value.absent(),
                required List<Artist> guestStars,
                Value<int> rowid = const Value.absent(),
              }) => EpisodesCompanion.insert(
                tmdbId: tmdbId,
                episodeNumber: episodeNumber,
                title: title,
                airDate: airDate,
                overview: overview,
                stillUrl: stillUrl,
                guestStars: guestStars,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EpisodesTable, Episode>(table),
                  BaseReferences<_$AppDatabase, $EpisodesTable, Episode>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EpisodesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EpisodesTable,
      Episode,
      $$EpisodesTableFilterComposer,
      $$EpisodesTableOrderingComposer,
      $$EpisodesTableAnnotationComposer,
      $$EpisodesTableCreateCompanionBuilder,
      $$EpisodesTableUpdateCompanionBuilder,
      (Episode, BaseReferences<_$AppDatabase, $EpisodesTable, Episode>),
      Episode,
      PrefetchHooks Function()
    >;
typedef $$StorageSourcesTableCreateCompanionBuilder =
    StorageSourcesCompanion Function({
      Value<int> id,
      required String sourceId,
      required String name,
      required String type,
      required String endpoint,
      required String rootPath,
      required bool enabled,
      required String username,
      required String password,
    });
typedef $$StorageSourcesTableUpdateCompanionBuilder =
    StorageSourcesCompanion Function({
      Value<int> id,
      Value<String> sourceId,
      Value<String> name,
      Value<String> type,
      Value<String> endpoint,
      Value<String> rootPath,
      Value<bool> enabled,
      Value<String> username,
      Value<String> password,
    });

class $$StorageSourcesTableFilterComposer extends Composer<_$AppDatabase, $StorageSourcesTable> {
  $$StorageSourcesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get endpoint =>
      $composableBuilder(column: $table.endpoint, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rootPath =>
      $composableBuilder(column: $table.rootPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get password =>
      $composableBuilder(column: $table.password, builder: (column) => ColumnFilters(column));
}

class $$StorageSourcesTableOrderingComposer extends Composer<_$AppDatabase, $StorageSourcesTable> {
  $$StorageSourcesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get endpoint =>
      $composableBuilder(column: $table.endpoint, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rootPath =>
      $composableBuilder(column: $table.rootPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get password =>
      $composableBuilder(column: $table.password, builder: (column) => ColumnOrderings(column));
}

class $$StorageSourcesTableAnnotationComposer extends Composer<_$AppDatabase, $StorageSourcesTable> {
  $$StorageSourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceId => $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type => $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get endpoint => $composableBuilder(column: $table.endpoint, builder: (column) => column);

  GeneratedColumn<String> get rootPath => $composableBuilder(column: $table.rootPath, builder: (column) => column);

  GeneratedColumn<bool> get enabled => $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<String> get username => $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get password => $composableBuilder(column: $table.password, builder: (column) => column);
}

class $$StorageSourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StorageSourcesTable,
          StorageSourceRow,
          $$StorageSourcesTableFilterComposer,
          $$StorageSourcesTableOrderingComposer,
          $$StorageSourcesTableAnnotationComposer,
          $$StorageSourcesTableCreateCompanionBuilder,
          $$StorageSourcesTableUpdateCompanionBuilder,
          (StorageSourceRow, BaseReferences<_$AppDatabase, $StorageSourcesTable, StorageSourceRow>),
          StorageSourceRow,
          PrefetchHooks Function()
        > {
  $$StorageSourcesTableTableManager(_$AppDatabase db, $StorageSourcesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$StorageSourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$StorageSourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$StorageSourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> endpoint = const Value.absent(),
                Value<String> rootPath = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> password = const Value.absent(),
              }) => StorageSourcesCompanion(
                id: id,
                sourceId: sourceId,
                name: name,
                type: type,
                endpoint: endpoint,
                rootPath: rootPath,
                enabled: enabled,
                username: username,
                password: password,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sourceId,
                required String name,
                required String type,
                required String endpoint,
                required String rootPath,
                required bool enabled,
                required String username,
                required String password,
              }) => StorageSourcesCompanion.insert(
                id: id,
                sourceId: sourceId,
                name: name,
                type: type,
                endpoint: endpoint,
                rootPath: rootPath,
                enabled: enabled,
                username: username,
                password: password,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StorageSourcesTable, StorageSourceRow>(table),
                  BaseReferences<_$AppDatabase, $StorageSourcesTable, StorageSourceRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StorageSourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StorageSourcesTable,
      StorageSourceRow,
      $$StorageSourcesTableFilterComposer,
      $$StorageSourcesTableOrderingComposer,
      $$StorageSourcesTableAnnotationComposer,
      $$StorageSourcesTableCreateCompanionBuilder,
      $$StorageSourcesTableUpdateCompanionBuilder,
      (StorageSourceRow, BaseReferences<_$AppDatabase, $StorageSourcesTable, StorageSourceRow>),
      StorageSourceRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MediaFilesTableTableManager get mediaFiles => $$MediaFilesTableTableManager(_db, _db.mediaFiles);
  $$MoviesTableTableManager get movies => $$MoviesTableTableManager(_db, _db.movies);
  $$TVShowsTableTableManager get tVShows => $$TVShowsTableTableManager(_db, _db.tVShows);
  $$SeasonsTableTableManager get seasons => $$SeasonsTableTableManager(_db, _db.seasons);
  $$EpisodesTableTableManager get episodes => $$EpisodesTableTableManager(_db, _db.episodes);
  $$StorageSourcesTableTableManager get storageSources => $$StorageSourcesTableTableManager(_db, _db.storageSources);
}
