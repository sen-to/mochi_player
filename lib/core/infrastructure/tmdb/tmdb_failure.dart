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

/// A request failure, distinct from a successful lookup with no matching metadata.
/// Deliberately excludes URLs, API keys and raw transport exceptions from diagnostics.
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
