// 【网络基础设施】发送 TMDB 请求并区分认证、限流、传输与响应失败。
// 不把请求失败当作成功的空结果，诊断信息避免包含凭据。

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:logger/logger.dart';
import 'package:mochi_player/core/data/tmdb/http_proxy_parser.dart';
import 'package:mochi_player/core/data/tmdb/tmdb_failure.dart';

class TmdbHttpClient {
  static const String _defaultApiKey = String.fromEnvironment('TMDB_API_KEY');
  static const String defaultApiBaseUrl = 'https://api.themoviedb.org/3';
  static const Duration _connectTimeout = Duration(seconds: 8);
  static const Duration _sendTimeout = Duration(seconds: 8);
  static const Duration _receiveTimeout = Duration(seconds: 12);

  TmdbHttpClient({Dio? dio, Logger? logger})
    : _dio = dio ?? Dio(),
      _logger = logger ?? Logger(printer: PrettyPrinter(methodCount: 0)) {
    _dio.options
      ..connectTimeout = _connectTimeout
      ..sendTimeout = _sendTimeout
      ..receiveTimeout = _receiveTimeout;
    _configureHttpClient();
  }

  final Dio _dio;
  final Logger _logger;
  String _apiKey = _defaultApiKey;
  String _baseUrl = defaultApiBaseUrl;
  String _proxyUrl = '';
  bool _proxyEnabled = false;

  bool get isConfigured => _apiKey.trim().isNotEmpty;

  void configure({String? apiKey, String? apiBaseUrl, String? proxyUrl, bool? proxyEnabled}) {
    final key = apiKey?.trim();
    if (key != null) _apiKey = key.isEmpty ? _defaultApiKey : key;
    final baseUrl = apiBaseUrl?.trim();
    if (baseUrl != null) {
      _baseUrl = baseUrl.isEmpty ? defaultApiBaseUrl : baseUrl.replaceFirst(RegExp(r'/+$'), '');
    }
    if (proxyUrl != null) _proxyUrl = proxyUrl.trim();
    if (proxyEnabled != null) _proxyEnabled = proxyEnabled;
    _configureHttpClient();
  }

  Future<Map<String, dynamic>?> get(
    String path, {
    required String operation,
    Map<String, dynamic> queryParameters = const {},
    String? notFoundMessage,
  }) async {
    if (!isConfigured) {
      throw const TmdbFailure(TmdbFailureKind.configuration);
    }
    try {
      final response = await _dio.get<dynamic>(
        '$_baseUrl$path',
        queryParameters: {'api_key': _apiKey, 'language': 'zh-CN', ...queryParameters},
      );
      final data = response.data;
      if (response.statusCode == 404) return null;
      if (response.statusCode != 200) throw _httpFailure(response);
      if (data is! Map<String, dynamic>) throw const TmdbFailure(TmdbFailureKind.invalidResponse);
      return data;
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        if (notFoundMessage != null) _logger.w(notFoundMessage);
        return null;
      }
      final failure = switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.transformTimeout => const TmdbFailure(TmdbFailureKind.timeout),
        DioExceptionType.connectionError ||
        DioExceptionType.badCertificate => const TmdbFailure(TmdbFailureKind.network),
        DioExceptionType.cancel => const TmdbFailure(TmdbFailureKind.cancelled),
        DioExceptionType.badResponse => _httpFailure(error.response!),
        DioExceptionType.unknown => TmdbFailure(
          error.error is FormatException ? TmdbFailureKind.invalidResponse : TmdbFailureKind.unknown,
        ),
      };
      _logger.w('$operation失败: $failure');
      throw failure;
    }
  }

  void _configureHttpClient() {
    final proxyConfig = _proxyEnabled && _proxyUrl.isNotEmpty ? HttpProxyParser.buildHttpProxy(_proxyUrl) : null;
    if (_proxyEnabled && _proxyUrl.isNotEmpty && proxyConfig == null) {
      _logger.w('⚠️ TMDB 代理地址无效，已改为直连: $_proxyUrl');
    }
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.findProxy = (_) => proxyConfig ?? 'DIRECT';
        return client;
      },
    );
  }

  TmdbFailure _httpFailure(Response<dynamic> response) {
    final status = response.statusCode;
    final kind = switch (status ?? 0) {
      401 || 403 => TmdbFailureKind.authentication,
      429 => TmdbFailureKind.rateLimited,
      >= 500 && <= 599 => TmdbFailureKind.server,
      _ => TmdbFailureKind.unknown,
    };
    final retryHeader = response.headers.value('retry-after');
    Duration? retryAfter;
    if (retryHeader != null) {
      final seconds = int.tryParse(retryHeader);
      if (seconds != null && seconds >= 0) {
        retryAfter = Duration(seconds: seconds);
      } else {
        try {
          final delay = HttpDate.parse(retryHeader).difference(DateTime.now().toUtc());
          retryAfter = delay.isNegative ? Duration.zero : delay;
        } on HttpException {
          // 可选重试提示无效时，仍应保留原有 HTTP 失败语义。
        }
      }
    }
    return TmdbFailure(kind, statusCode: status, retryAfter: retryAfter);
  }
}
