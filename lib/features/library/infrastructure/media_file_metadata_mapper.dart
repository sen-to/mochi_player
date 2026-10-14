import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/features/library/infrastructure/filename_parser.dart';

/// Creates immutable scan snapshots. Persistence decides which fields may change.
abstract final class MediaFileMetadataMapper {
  static MediaFile createFile({
    required String sourceId,
    required String path,
    required String fileName,
    required int size,
    required ParsedMediaFilename metadata,
  }) => reparse(
    MediaFile(
      id: 0,
      sourceId: sourceId,
      path: path,
      fileName: fileName,
      parsedTitle: metadata.title,
      size: size,
      addedAt: DateTime.now().toUtc(),
    ),
    metadata,
  );

  static MediaFile reparse(MediaFile file, ParsedMediaFilename metadata) {
    final type = metadata.season != null || metadata.episode != null
        ? MediaType.episode
        : metadata.title.isNotEmpty
        ? MediaType.movie
        : MediaType.unknown;
    final changedType = file.mediaType != MediaType.unknown && file.mediaType != type;
    return file.copyWith(
      parsedTitle: metadata.title,
      parsedYear: metadata.year,
      parsedSeason: metadata.season,
      parsedEpisode: metadata.episode,
      mediaType: type,
      explicitTmdbId: _nonEmpty(metadata.tmdbId),
      container: metadata.container,
      height: metadata.height,
      videoCodec: metadata.videoCodec,
      audioCodec: metadata.audioCodec,
      audioChannels: metadata.audioChannels,
      isHdr: metadata.isHdr,
      hdrFormat: metadata.hdrFormat,
      versionLabel: _nonEmpty(metadata.versionLabel),
      movieTmdbId: changedType ? null : file.movieTmdbId,
      tvShowTmdbId: changedType ? null : file.tvShowTmdbId,
      episodeKey: changedType ? null : file.episodeKey,
      metadataMatchStatus: changedType ? MetadataMatchStatus.pending : file.metadataMatchStatus,
    );
  }

  static String? _nonEmpty(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
