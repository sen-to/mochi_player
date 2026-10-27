// 【行为测试】验证将 TMDB 响应转换为媒体、演员、季集及趋势数据。
// 测试对象的职责边界：不发起网络请求，不保存数据库。

import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/data/tmdb/tmdb_metadata_mapper.dart';

void main() {
  const mapper = TmdbMetadataMapper();

  test('maps a season and its episodes from one response', () {
    final result = mapper.seasonFromJson(
      {
        'name': 'Season 1',
        'poster_path': '/season.jpg',
        'episodes': [
          {
            'id': 777,
            'episode_number': 1,
            'name': 'Pilot',
            'air_date': '2025-01-02',
            'still_path': '/episode.jpg',
            'guest_stars': [
              {'id': 9, 'name': 'Guest', 'character': 'Self'},
            ],
          },
        ],
      },
      '42',
      1,
    );

    expect(result.season.tvShowTmdbId, '42');
    expect(result.season.numberOfEpisodes, 1);
    expect(result.episodes.single.tmdbId, '777');
    expect(result.episodes.single.tvShowTmdbId, '42');
    expect(result.episodes.single.seasonNumber, 1);
    expect(result.episodes.single.episodeKey, '42_s1e1');
    expect(result.episodes.single.title, 'Pilot');
    expect(result.episodes.single.stillUrl, 'https://image.tmdb.org/t/p/w1280/episode.jpg');
  });

  test('maps movie details and selects the preferred logo language', () {
    final movie = mapper.movieFromJson({
      'id': 7,
      'title': '电影',
      'original_title': 'Movie',
      'release_date': '2024-03-04',
      'vote_average': 8,
      'genres': [
        {'name': 'Drama'},
      ],
      'images': {
        'logos': [
          {'iso_639_1': 'en', 'file_path': '/en.png'},
          {'iso_639_1': 'zh', 'file_path': '/zh.png'},
        ],
      },
    });

    expect(movie.tmdbId, '7');
    expect(movie.releaseYear, 2024);
    expect(movie.genres, ['Drama']);
    expect(movie.logoUrl, 'https://image.tmdb.org/t/p/w500/zh.png');
  });
}
