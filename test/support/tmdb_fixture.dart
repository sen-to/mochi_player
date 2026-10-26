import 'package:dio/dio.dart';
import 'package:mochi_player/core/infrastructure/tmdb/tmdb_client.dart';
import 'package:mochi_player/core/infrastructure/tmdb/tmdb_service.dart';

/// Exercises the real client and service without opening network connections.
TmdbService tmdbFixture(void Function(RequestOptions, RequestInterceptorHandler) respond) {
  final dio = Dio();
  final client = TmdbClient(dio: dio);
  client.configure(apiKey: 'test-key');
  dio.interceptors.add(InterceptorsWrapper(onRequest: respond));
  return TmdbService(client: client);
}
