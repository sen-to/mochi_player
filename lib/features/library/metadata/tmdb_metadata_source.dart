import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/domain/media/season_metadata.dart';
import 'package:mochi_player/core/infrastructure/tmdb/tmdb_failure.dart';
import 'package:mochi_player/core/infrastructure/tmdb/tmdb_service.dart';
import 'package:mochi_player/features/library/metadata/metadata_source.dart';

class TmdbMetadataSource implements MetadataSource {
  TmdbMetadataSource({required TmdbService service}) : _service = service;

  final TmdbService _service;

  @override
  bool get isConfigured => _service.isConfigured;

  @override
  Future<Movie?> fetchMovieById(String id) => _request(() => _service.fetchMovieById(int.parse(id)));

  @override
  Future<TVShow?> fetchTVShowById(String id) => _request(() => _service.fetchTVShowById(int.parse(id)));

  @override
  Future<Movie?> searchMovie(String title, {int? year}) => _request(() => _service.fetchMovie(title, year: year));

  @override
  Future<TVShow?> searchTVShow(String title, {int? year}) => _request(() => _service.fetchTVShow(title, year: year));

  @override
  Future<SeasonMetadata?> fetchSeason(String showId, int seasonNumber) =>
      _request(() => _service.fetchSeason(int.parse(showId), seasonNumber, showTmdbId: showId));

  Future<T> _request<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on TmdbFailure catch (failure) {
      throw MetadataRequestFailure(
        userFailure: failure.userFailure,
        isRetryable: failure.isRetryable,
        statusCode: failure.statusCode,
        retryAfter: failure.retryAfter,
      );
    }
  }
}
