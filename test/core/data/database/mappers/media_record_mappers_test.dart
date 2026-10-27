// 【映射测试】验证数据库 DO 与业务模型的字段往返及 JSON、枚举隔离。
// 使用生成的数据库记录比较值，不依赖原生播放器或真实网络。

import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/data/database/mappers/episode_mapper.dart';
import 'package:mochi_player/core/data/database/mappers/media_file_mapper.dart';
import 'package:mochi_player/core/data/database/mappers/movie_mapper.dart';
import 'package:mochi_player/core/data/database/mappers/season_mapper.dart';
import 'package:mochi_player/core/data/database/mappers/storage_source_mapper.dart';
import 'package:mochi_player/core/data/database/mappers/tv_show_mapper.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/domain/storage/models.dart';

void main() {
  const actor = Artist(tmdbId: '7', name: '演员 "A"', character: '角色', profileUrl: '/cast.jpg');
  test('media file roundtrip preserves identity, technical attributes and user state', () {
    final model = MediaFile(
      id: 42,
      sourceId: 'nas',
      path: '/电影.mkv',
      fileName: '电影.mkv',
      parsedTitle: '电影',
      parsedYear: 2001,
      mediaType: MediaType.movie,
      metadataMatchStatus: MetadataMatchStatus.confirmed,
      explicitTmdbId: '1',
      movieTmdbId: '1',
      size: 2048,
      container: 'mkv',
      width: 3840,
      height: 2160,
      videoCodec: 'hevc',
      audioCodec: 'truehd',
      audioChannels: '7.1',
      isHdr: true,
      hdrFormat: 'dolby_vision',
      versionLabel: '导演剪辑',
      duration: 100000,
      position: 40000,
      watchStatus: WatchStatus.watching,
      lastWatchedAt: DateTime.utc(2026, 10, 27),
      isFavorite: true,
      addedAt: DateTime.utc(2026),
    );
    final row = MediaFileMapper.toDO(model);
    expect(row.mediaType, 'movie');
    expect(row.watchStatus, 'watching');
    expect(row.metadataMatchStatus, 'confirmed');
    final restored = MediaFileMapper.toDomain(row);
    expect(restored.storageKey, model.storageKey);
    expect(restored.watchStatus, WatchStatus.watching);
    expect(MediaFileMapper.toDO(restored), row);
    expect(MediaFileMapper.toDomain(MediaFileMapper.toDO(model.copyWith(movieTmdbId: null))).movieTmdbId, isNull);
  });

  test('movie records encode JSON while domain models expose typed lists', () {
    const movie = Movie(tmdbId: '1', title: '电影', genres: ['剧情', '科幻'], cast: [actor], rating: 8.5);
    final row = MovieMapper.toDO(movie);
    expect(row.cast, contains('演员'));
    final restored = MovieMapper.toDomain(row);
    expect(restored.cast.single.character, '角色');
    expect(restored.genres, ['剧情', '科幻']);
    expect(MovieMapper.toDO(restored), row);
  });

  test('show record roundtrip preserves provider metadata separately from loaded seasons', () {
    const show = TVShow(
      tmdbId: '2',
      title: '剧集',
      status: 'Ended',
      numberOfSeasons: 3,
      numberOfEpisodes: 30,
      cast: [actor],
      genres: ['悬疑'],
      certification: 'TV-14',
    );
    final row = TVShowMapper.toDO(show);
    final restored = TVShowMapper.toDomain(row);
    expect(restored.numberOfSeasons, 3);
    expect(restored.seasons, isEmpty);
    expect(TVShowMapper.toDO(restored), row);
  });

  test('season records do not embed separately stored episodes', () {
    const season = Season(tvShowTmdbId: '2', seasonNumber: 0, title: '特别篇', numberOfEpisodes: 2);
    final row = SeasonMapper.toDO(season);
    expect(SeasonMapper.toDomain(row).episodes, isEmpty);
    expect(SeasonMapper.toDO(SeasonMapper.toDomain(row)), row);
  });

  test('episode records preserve the derived key, provider id and guest stars', () {
    const episode = Episode(
      tvShowTmdbId: '2',
      seasonNumber: 0,
      episodeNumber: 1,
      tmdbId: '99',
      title: '特别篇',
      guestStars: [actor],
    );
    final row = EpisodeMapper.toDO(episode);
    expect(row.episodeKey, '2_s0e1');
    final restored = EpisodeMapper.toDomain(row);
    expect(restored.tmdbId, '99');
    expect(restored.guestStars.single.profileUrl, '/cast.jpg');
    expect(EpisodeMapper.toDO(restored), row);
  });

  test('source mapping keeps credentials outside the domain source and applies domain normalization', () {
    const source = StorageSource(
      id: ' nas ',
      name: ' NAS ',
      type: StorageSourceType.smb,
      endpoint: ' smb://server/share ',
      rootPath: ' Movies/ ',
    );
    const credentials = StorageCredentials(username: ' viewer ', password: ' password ');
    final row = StorageSourceMapper.toDO(source, credentials);
    expect(StorageSourceMapper.toDomain(row), source.normalized());
    expect(row.rootPath, '/Movies');
    expect(StorageSourceMapper.toCredentials(row).username, 'viewer');
    expect(StorageSourceMapper.toCredentials(row).password, ' password ');
  });
}
