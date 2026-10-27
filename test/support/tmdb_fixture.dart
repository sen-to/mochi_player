// 【测试替身】将真实 TMDB 客户端接入可控请求拦截器。
// 验证响应和失败转换，不请求真实网络。

import 'package:dio/dio.dart';
import 'package:mochi_player/core/data/tmdb/tmdb_api.dart';
import 'package:mochi_player/core/data/tmdb/tmdb_http_client.dart';

/// 使用真实客户端与服务逻辑，但不建立网络连接。
TmdbApi tmdbFixture(void Function(RequestOptions, RequestInterceptorHandler) respond) {
  final dio = Dio();
  final client = TmdbHttpClient(dio: dio);
  client.configure(apiKey: 'test-key');
  dio.interceptors.add(InterceptorsWrapper(onRequest: respond));
  return TmdbApi(client: client);
}
