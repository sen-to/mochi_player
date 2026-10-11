import 'package:mochi_player/core/domain/media/media_type.dart';
import 'package:mochi_player/core/domain/media/metadata_match_status.dart';
import 'package:mochi_player/core/domain/media/watch_status.dart';

/// 媒体文件 Domain Model
class MediaFile {
  final int id;
  final String sourceId;
  final String path;
  final String fileName;
  final String parsedTitle;
  final int? parsedYear;
  final int? parsedSeason;
  final int? parsedEpisode;
  final MediaType mediaType;
  final String? explicitTmdbId;
  final MetadataMatchStatus metadataMatchStatus;
  final String? movieTmdbId;
  final String? tvShowTmdbId;
  final String? episodeTmdbId;
  final int size;
  final String? container;
  final int? width;
  final int? height;
  final String? videoCodec;
  final String? audioCodec;
  final String? audioChannels;
  final bool isHdr;
  final String? hdrFormat;
  final String? versionLabel;
  final int duration;
  final int position;
  final WatchStatus watchStatus;
  final DateTime? lastWatchedAt;
  final bool isFavorite;
  final DateTime addedAt;

  const MediaFile({
    required this.id,
    this.sourceId = '',
    required this.path,
    required this.fileName,
    required this.parsedTitle,
    this.parsedYear,
    this.parsedSeason,
    this.parsedEpisode,
    this.mediaType = MediaType.unknown,
    this.explicitTmdbId,
    this.metadataMatchStatus = MetadataMatchStatus.pending,
    this.movieTmdbId,
    this.tvShowTmdbId,
    this.episodeTmdbId,
    this.size = 0,
    this.container,
    this.width,
    this.height,
    this.videoCodec,
    this.audioCodec,
    this.audioChannels,
    this.isHdr = false,
    this.hdrFormat,
    this.versionLabel,
    this.duration = 0,
    this.position = 0,
    this.watchStatus = WatchStatus.notStarted,
    this.lastWatchedAt,
    this.isFavorite = false,
    required this.addedAt,
  });

  /// Stable persistence identity within the configured source.
  String get storageKey => '$sourceId:$path';

  /// Metadata ID of the directly playable item: movie for movies, episode for
  /// TV episodes. Parent show IDs intentionally live in [tvShowTmdbId].
  String? get tmdbId => movieTmdbId ?? episodeTmdbId;

  /// 播放进度百分比
  double get progress => duration == 0 ? 0 : position / duration;

  /// 质量标签
  String get quality {
    if (height == null) return '';
    if (height! >= 2160) return '4K';
    if (height! >= 1080) return '1080p';
    if (height! >= 720) return '720p';
    return 'SD';
  }

  static const _unchanged = Object();

  /// Returns a new file snapshot; nullable fields can be explicitly cleared.
  MediaFile copyWith({
    int? id,
    String? sourceId,
    String? path,
    String? fileName,
    String? parsedTitle,
    Object? parsedYear = _unchanged,
    Object? parsedSeason = _unchanged,
    Object? parsedEpisode = _unchanged,
    MediaType? mediaType,
    Object? explicitTmdbId = _unchanged,
    MetadataMatchStatus? metadataMatchStatus,
    Object? movieTmdbId = _unchanged,
    Object? tvShowTmdbId = _unchanged,
    Object? episodeTmdbId = _unchanged,
    int? size,
    Object? container = _unchanged,
    Object? width = _unchanged,
    Object? height = _unchanged,
    Object? videoCodec = _unchanged,
    Object? audioCodec = _unchanged,
    Object? audioChannels = _unchanged,
    bool? isHdr,
    Object? hdrFormat = _unchanged,
    Object? versionLabel = _unchanged,
    int? duration,
    int? position,
    WatchStatus? watchStatus,
    Object? lastWatchedAt = _unchanged,
    bool? isFavorite,
    DateTime? addedAt,
  }) => MediaFile(
    id: id ?? this.id,
    sourceId: sourceId ?? this.sourceId,
    path: path ?? this.path,
    fileName: fileName ?? this.fileName,
    parsedTitle: parsedTitle ?? this.parsedTitle,
    parsedYear: identical(parsedYear, _unchanged) ? this.parsedYear : parsedYear as int?,
    parsedSeason: identical(parsedSeason, _unchanged) ? this.parsedSeason : parsedSeason as int?,
    parsedEpisode: identical(parsedEpisode, _unchanged) ? this.parsedEpisode : parsedEpisode as int?,
    mediaType: mediaType ?? this.mediaType,
    explicitTmdbId: identical(explicitTmdbId, _unchanged) ? this.explicitTmdbId : explicitTmdbId as String?,
    metadataMatchStatus: metadataMatchStatus ?? this.metadataMatchStatus,
    movieTmdbId: identical(movieTmdbId, _unchanged) ? this.movieTmdbId : movieTmdbId as String?,
    tvShowTmdbId: identical(tvShowTmdbId, _unchanged) ? this.tvShowTmdbId : tvShowTmdbId as String?,
    episodeTmdbId: identical(episodeTmdbId, _unchanged) ? this.episodeTmdbId : episodeTmdbId as String?,
    size: size ?? this.size,
    container: identical(container, _unchanged) ? this.container : container as String?,
    width: identical(width, _unchanged) ? this.width : width as int?,
    height: identical(height, _unchanged) ? this.height : height as int?,
    videoCodec: identical(videoCodec, _unchanged) ? this.videoCodec : videoCodec as String?,
    audioCodec: identical(audioCodec, _unchanged) ? this.audioCodec : audioCodec as String?,
    audioChannels: identical(audioChannels, _unchanged) ? this.audioChannels : audioChannels as String?,
    isHdr: isHdr ?? this.isHdr,
    hdrFormat: identical(hdrFormat, _unchanged) ? this.hdrFormat : hdrFormat as String?,
    versionLabel: identical(versionLabel, _unchanged) ? this.versionLabel : versionLabel as String?,
    duration: duration ?? this.duration,
    position: position ?? this.position,
    watchStatus: watchStatus ?? this.watchStatus,
    lastWatchedAt: identical(lastWatchedAt, _unchanged) ? this.lastWatchedAt : lastWatchedAt as DateTime?,
    isFavorite: isFavorite ?? this.isFavorite,
    addedAt: addedAt ?? this.addedAt,
  );
}
