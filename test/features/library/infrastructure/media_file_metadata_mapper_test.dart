import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/features/library/infrastructure/filename_parser.dart';
import 'package:mochi_player/features/library/infrastructure/media_file_metadata_mapper.dart';

void main() {
  test('creates a media file from parsed filename metadata', () {
    final row = MediaFileMetadataMapper.createFile(
      sourceId: 'nas-a',
      path: '/shows/example.mkv',
      fileName: 'example.mkv',
      size: 1024,
      metadata: const ParsedMediaFilename(
        title: 'Example',
        year: 2026,
        season: 2,
        episode: 3,
        tmdbId: ' 123_s2e3 ',
        container: 'mkv',
        height: 2160,
        videoCodec: 'hevc',
        audioCodec: 'truehd',
        audioChannels: '7.1',
        isHdr: true,
        hdrFormat: 'dolby_vision',
        versionLabel: '2160p BluRay',
      ),
    );

    expect(row.path, '/shows/example.mkv');
    expect(row.sourceId, 'nas-a');
    expect(row.storageKey, 'nas-a:/shows/example.mkv');
    expect(row.fileName, 'example.mkv');
    expect(row.size, 1024);
    expect(row.parsedTitle, 'Example');
    expect(row.parsedYear, 2026);
    expect(row.parsedSeason, 2);
    expect(row.parsedEpisode, 3);
    expect(row.mediaType, MediaType.episode);
    expect(row.explicitTmdbId, '123_s2e3');
    expect(row.movieTmdbId, isNull);
    expect(row.episodeKey, isNull);
    expect(row.container, 'mkv');
    expect(row.height, 2160);
    expect(row.videoCodec, 'hevc');
    expect(row.audioCodec, 'truehd');
    expect(row.audioChannels, '7.1');
    expect(row.isHdr, isTrue);
    expect(row.hdrFormat, 'dolby_vision');
    expect(row.versionLabel, '2160p BluRay');
  });

  test('preserves a confirmed movie match when reparsing has no embedded id', () {
    final original = MediaFile(
      path: '/movies/example.mkv',
      fileName: 'example.mkv',
      parsedTitle: 'Old title',
      movieTmdbId: '456',
      position: 12000,
      isFavorite: true,
      id: 0,
      sourceId: '',
      addedAt: DateTime.now(),
    );

    final row = MediaFileMetadataMapper.reparse(
      original,
      const ParsedMediaFilename(title: 'Example', versionLabel: ''),
    );

    expect(row.parsedTitle, 'Example');
    expect(row.mediaType, MediaType.movie);
    expect(row.movieTmdbId, '456');
    expect(row.explicitTmdbId, isNull);
    expect(row.versionLabel, isNull);
    expect(row.position, 12000);
    expect(row.isFavorite, isTrue);
  });

  test('keeps an explicit TMDB id separate from a confirmed match', () {
    final original = MediaFile(
      path: '/movies/{tmdb-789}/example.mkv',
      fileName: 'example.mkv',
      parsedTitle: 'Example',
      movieTmdbId: '456',
      id: 0,
      sourceId: '',
      addedAt: DateTime.now(),
    );

    final row = MediaFileMetadataMapper.reparse(original, const ParsedMediaFilename(title: 'Example', tmdbId: '789'));

    expect(row.explicitTmdbId, '789');
    expect(row.movieTmdbId, '456');
  });

  test('clears incompatible confirmed links when media type changes', () {
    final original = MediaFile(
      mediaType: MediaType.movie,
      movieTmdbId: '1555290',
      id: 0,
      sourceId: '',
      path: '',
      fileName: '',
      parsedTitle: '',
      addedAt: DateTime.now(),
    );

    final row = MediaFileMetadataMapper.reparse(
      original,
      const ParsedMediaFilename(title: '街头餐厅斗士', season: 1, episode: 1, isEpisode: true),
    );

    expect(row.mediaType, MediaType.episode);
    expect(row.movieTmdbId, isNull);
    expect(row.episodeKey, isNull);
  });
}
