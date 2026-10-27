// 【行为测试】验证发送 TMDB 请求并区分认证、限流、传输与响应失败。
// 测试对象的职责边界：不把请求失败当作成功的空结果，诊断信息避免包含凭据。

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/data/tmdb/tmdb_failure.dart';

import '../../../support/tmdb_fixture.dart';

void main() {
  for (final isMovie in [true, false]) {
    test('search preserves provider ranking for ${isMovie ? 'movies' : 'shows'}', () async {
      final requests = <String>[];
      final api = tmdbFixture((request, handler) {
        requests.add(request.uri.path);
        final isSearch = request.uri.path.contains('/search/');
        if (isSearch) expect(request.queryParameters['query'], '完整标题');
        handler.resolve(
          Response<dynamic>(
            requestOptions: request,
            statusCode: 200,
            data: isSearch
                ? {
                    'results': [
                      {'id': 2},
                      {'id': 1},
                    ],
                  }
                : {'id': 2, if (isMovie) 'title': '首选电影' else 'name': '首选剧集'},
          ),
        );
      });
      final result = isMovie ? await api.fetchMovie('完整标题') : await api.fetchTVShow('完整标题');
      expect(result?.tmdbId, '2');
      expect(requests, [isMovie ? '/3/search/movie' : '/3/search/tv', isMovie ? '/3/movie/2' : '/3/tv/2']);
    });
  }
  for (final entry in {
    401: TmdbFailureKind.authentication,
    403: TmdbFailureKind.authentication,
    429: TmdbFailureKind.rateLimited,
    503: TmdbFailureKind.server,
  }.entries) {
    for (final reject in [false, true]) {
      test('HTTP ${entry.key} preserves failure kind and status (Dio rejection: $reject)', () async {
        final service = tmdbFixture((request, handler) {
          final response = Response<dynamic>(
            requestOptions: request,
            statusCode: entry.key,
            headers: Headers.fromMap({
              'retry-after': ['30'],
            }),
          );
          if (reject) {
            handler.reject(
              DioException(requestOptions: request, response: response, type: DioExceptionType.badResponse),
            );
          } else {
            handler.resolve(response);
          }
        });
        await expectLater(
          service.fetchMovieById(1),
          throwsA(
            isA<TmdbFailure>()
                .having((e) => e.kind, 'kind', entry.value)
                .having((e) => e.statusCode, 'status', entry.key)
                .having((e) => e.retryAfter, 'retry hint', const Duration(seconds: 30)),
          ),
        );
      });
    }
  }

  for (final entry in {
    DioExceptionType.connectionTimeout: TmdbFailureKind.timeout,
    DioExceptionType.sendTimeout: TmdbFailureKind.timeout,
    DioExceptionType.receiveTimeout: TmdbFailureKind.timeout,
    DioExceptionType.transformTimeout: TmdbFailureKind.timeout,
    DioExceptionType.connectionError: TmdbFailureKind.network,
    DioExceptionType.badCertificate: TmdbFailureKind.network,
    DioExceptionType.cancel: TmdbFailureKind.cancelled,
  }.entries) {
    test('${entry.key.name} propagates a sanitized typed failure', () async {
      final service = tmdbFixture((request, handler) {
        handler.reject(DioException(requestOptions: request, type: entry.key, message: 'secret-key'));
      });
      await expectLater(
        service.fetchMovieById(1),
        throwsA(
          isA<TmdbFailure>()
              .having((e) => e.kind, 'kind', entry.value)
              .having((e) => e.toString(), 'safe diagnostic', isNot(contains('secret-key'))),
        ),
      );
    });
  }

  test('only a missing resource or successful empty search returns no match', () async {
    final service = tmdbFixture(
      (request, handler) => handler.resolve(
        Response<dynamic>(
          requestOptions: request,
          statusCode: request.uri.path.contains('/search/') ? 200 : 404,
          data: {'results': []},
        ),
      ),
    );
    expect(await service.fetchMovieById(1), isNull);
    expect(await service.fetchMovie('Missing movie'), isNull);
    expect(await service.fetchTVShow('Missing show'), isNull);
    expect(await service.fetchSeason(1, 1, showTmdbId: '1'), isNull);
  });

  for (final data in [
    [],
    {'status_message': 'not a search result'},
    {
      'results': [42],
    },
  ]) {
    test('malformed response $data is not an empty search result', () async {
      final service = tmdbFixture(
        (request, handler) => handler.resolve(Response<dynamic>(requestOptions: request, statusCode: 200, data: data)),
      );
      await expectLater(
        service.fetchMovie('Example'),
        throwsA(isA<TmdbFailure>().having((e) => e.kind, 'kind', TmdbFailureKind.invalidResponse)),
      );
    });
  }

  test('missing search and collection endpoints are failures rather than empty results', () async {
    final service = tmdbFixture(
      (request, handler) => handler.resolve(Response<dynamic>(requestOptions: request, statusCode: 404)),
    );
    final unavailable = throwsA(
      isA<TmdbFailure>()
          .having((e) => e.kind, 'kind', TmdbFailureKind.invalidResponse)
          .having((e) => e.statusCode, 'status', 404),
    );
    await expectLater(service.fetchMovie('Example'), unavailable);
    await expectLater(service.fetchTVShow('Example'), unavailable);
    await expectLater(service.fetchTrendingMovies(), unavailable);
    await expectLater(service.fetchTrendingTV(), unavailable);
    await expectLater(service.fetchTopRated(), unavailable);
  });

  test('malformed movie and season details are failures rather than absent metadata', () async {
    final service = tmdbFixture(
      (request, handler) => handler.resolve(Response<dynamic>(requestOptions: request, statusCode: 200, data: {})),
    );
    final invalid = throwsA(isA<TmdbFailure>().having((e) => e.kind, 'kind', TmdbFailureKind.invalidResponse));
    await expectLater(service.fetchMovieById(1), invalid);
    await expectLater(service.fetchTVShowById(1), invalid);
    await expectLater(service.fetchSeason(1, 1, showTmdbId: '1'), invalid);
  });

  test('invalid detail field types retain the response failure category', () async {
    final service = tmdbFixture(
      (request, handler) => handler.resolve(
        Response<dynamic>(
          requestOptions: request,
          statusCode: 200,
          data: {'id': 1, 'title': 'Movie', 'vote_average': 'invalid'},
        ),
      ),
    );
    await expectLater(
      service.fetchMovieById(1),
      throwsA(isA<TmdbFailure>().having((e) => e.kind, 'kind', TmdbFailureKind.invalidResponse)),
    );
  });

  test('HTTP-date retry hint survives the transport boundary', () async {
    final retryAt = DateTime.now().toUtc().add(const Duration(minutes: 1));
    final service = tmdbFixture(
      (request, handler) => handler.resolve(
        Response<dynamic>(
          requestOptions: request,
          statusCode: 429,
          headers: Headers.fromMap({
            'retry-after': [HttpDate.format(retryAt)],
          }),
        ),
      ),
    );
    await expectLater(
      service.fetchMovieById(1),
      throwsA(
        isA<TmdbFailure>()
            .having((e) => e.retryAfter, 'retry hint', isNotNull)
            .having((e) => e.isRetryable, 'retryable', isTrue),
      ),
    );
  });

  for (final hint in ['invalid', '-1']) {
    test('invalid retry hint $hint does not hide a rate limit', () async {
      final service = tmdbFixture(
        (request, handler) => handler.resolve(
          Response<dynamic>(
            requestOptions: request,
            statusCode: 429,
            headers: Headers.fromMap({
              'retry-after': [hint],
            }),
          ),
        ),
      );
      await expectLater(
        service.fetchMovieById(1),
        throwsA(
          isA<TmdbFailure>()
              .having((e) => e.kind, 'kind', TmdbFailureKind.rateLimited)
              .having((e) => e.retryAfter, 'hint', isNull),
        ),
      );
    });
  }
}
