import 'package:mochi_player/core/domain/app_failure.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/domain/media/season_metadata.dart';

/// Metadata operations used by matching. Null means a successful lookup found nothing.
abstract interface class MetadataSource {
  bool get isConfigured;

  Future<Movie?> fetchMovieById(String id);
  Future<TVShow?> fetchTVShowById(String id);
  Future<Movie?> searchMovie(String title, {int? year});
  Future<TVShow?> searchTVShow(String title, {int? year});
  Future<SeasonMetadata?> fetchSeason(String showId, int seasonNumber);
}

/// An actionable request failure without exposing a backend exception to orchestration.
class MetadataRequestFailure implements Exception {
  const MetadataRequestFailure({
    required this.userFailure,
    required this.isRetryable,
    this.statusCode,
    this.retryAfter,
  });

  final AppFailure userFailure;
  final bool isRetryable;
  final int? statusCode;
  final Duration? retryAfter;

  @override
  String toString() => 'MetadataRequestFailure(${userFailure.name}, statusCode: $statusCode)';
}
