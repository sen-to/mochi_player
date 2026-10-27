// 【行为测试】验证将共享 TMDB 服务转换为匹配流程所需能力。
// 测试对象的职责边界：在适配边界转换错误，业务编排不依赖网络客户端类型。

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/app_failure.dart';
import 'package:mochi_player/features/library/metadata/application/metadata_source.dart';
import 'package:mochi_player/features/library/metadata/data/tmdb_metadata_source.dart';

import '../../../../support/tmdb_fixture.dart';

void main() {
  test('translates backend failures while preserving retry metadata', () async {
    final source = TmdbMetadataSource(
      api: tmdbFixture(
        (request, handler) => handler.resolve(
          Response<dynamic>(
            requestOptions: request,
            statusCode: 429,
            headers: Headers.fromMap({
              'retry-after': ['30'],
            }),
          ),
        ),
      ),
    );
    await expectLater(
      source.searchMovie('Movie'),
      throwsA(
        isA<MetadataRequestFailure>()
            .having((failure) => failure.userFailure, 'user failure', AppFailure.tmdbRateLimited)
            .having((failure) => failure.statusCode, 'status', 429)
            .having((failure) => failure.isRetryable, 'retryable', isTrue)
            .having((failure) => failure.retryAfter, 'retry hint', const Duration(seconds: 30)),
      ),
    );
  });

  test('returns domain season metadata with the requested show identity', () async {
    final source = TmdbMetadataSource(
      api: tmdbFixture(
        (request, handler) => handler.resolve(
          Response<dynamic>(
            requestOptions: request,
            statusCode: 200,
            data: {
              'name': 'Season',
              'episodes': [
                {'id': 42, 'episode_number': 1, 'name': 'Episode'},
              ],
            },
          ),
        ),
      ),
    );
    final season = (await source.fetchSeason('12', 2))!;
    expect(season.season.tvShowTmdbId, '12');
    expect(season.episodes.single.episodeKey, '12_s2e1');
  });
}
