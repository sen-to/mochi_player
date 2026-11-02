// 【行为测试】验证 TMDB 密钥只由用户配置决定。
// 职责边界：不内置密钥、清空即失效、未配置时不发出请求。

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/data/tmdb/tmdb_failure.dart';
import 'package:mochi_player/core/data/tmdb/tmdb_http_client.dart';

/// 记录请求并直接返回成功响应，用于观察参数而不建立网络连接。
List<RequestOptions> attachRecorder(Dio dio, {Map<String, dynamic> data = const {'results': []}}) {
  final requests = <RequestOptions>[];
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (request, handler) {
        requests.add(request);
        handler.resolve(Response<dynamic>(requestOptions: request, statusCode: 200, data: data));
      },
    ),
  );
  return requests;
}

void main() {
  test('没有内置密钥，缺省即为未配置', () {
    expect(TmdbHttpClient().isConfigured, isFalse);
  });

  test('清空密钥后回到未配置状态，不回退到默认值', () {
    final client = TmdbHttpClient()..configure(apiKey: 'user-key');
    expect(client.isConfigured, isTrue);

    client.configure(apiKey: '');

    expect(client.isConfigured, isFalse);
  });

  test('只有空白的密钥视为未配置', () {
    final client = TmdbHttpClient()..configure(apiKey: '   ');

    expect(client.isConfigured, isFalse);
  });

  test('未传 apiKey 时保留原有密钥', () async {
    final dio = Dio();
    final requests = attachRecorder(dio);
    final client = TmdbHttpClient(dio: dio)..configure(apiKey: 'user-key');

    client.configure(apiBaseUrl: 'https://example.com/3');
    await client.get('/trending/movie/day', operation: '测试');

    expect(requests.single.queryParameters['api_key'], 'user-key');
  });

  test('未配置密钥时不发出请求，直接报配置失败', () async {
    final dio = Dio();
    final requests = attachRecorder(dio);
    final client = TmdbHttpClient(dio: dio);

    await expectLater(
      client.get('/trending/movie/day', operation: '测试'),
      throwsA(isA<TmdbFailure>().having((e) => e.kind, 'kind', TmdbFailureKind.configuration)),
    );
    expect(requests, isEmpty);
  });
}
