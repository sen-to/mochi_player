// 【失败模型】描述 TMDB 请求失败的类别及可用重试信息。
// 不携带 API 密钥或原始请求地址，空结果与请求失败分开表达。

import 'package:mochi_player/core/domain/app_failure.dart';

enum TmdbFailureKind {
  configuration,
  authentication,
  rateLimited,
  timeout,
  network,
  cancelled,
  server,
  invalidResponse,
  unknown,
}

/// 请求失败与成功但无匹配元数据分别表达；诊断信息不包含 URL、API 密钥或原始传输异常。
class TmdbFailure implements Exception {
  const TmdbFailure(this.kind, {this.statusCode, this.retryAfter});

  final TmdbFailureKind kind;
  final int? statusCode;
  final Duration? retryAfter;

  bool get isRetryable => switch (kind) {
    TmdbFailureKind.rateLimited || TmdbFailureKind.timeout || TmdbFailureKind.network || TmdbFailureKind.server => true,
    _ => false,
  };

  AppFailure get userFailure => switch (kind) {
    TmdbFailureKind.configuration || TmdbFailureKind.authentication => AppFailure.tmdbAuthentication,
    TmdbFailureKind.rateLimited => AppFailure.tmdbRateLimited,
    TmdbFailureKind.timeout => AppFailure.tmdbTimeout,
    TmdbFailureKind.network => AppFailure.tmdbNetwork,
    TmdbFailureKind.server || TmdbFailureKind.invalidResponse => AppFailure.tmdbResponse,
    _ => AppFailure.scrapeFailed,
  };

  @override
  String toString() => 'TmdbFailure(${kind.name}, statusCode: $statusCode)';
}
