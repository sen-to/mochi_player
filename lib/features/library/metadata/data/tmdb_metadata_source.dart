// 【外部服务适配】将共享 TMDB API 转换为匹配流程所需能力。
// 在适配边界转换错误，业务编排不依赖网络客户端类型。

import 'package:mochi_player/core/data/tmdb/tmdb_api.dart';
import 'package:mochi_player/core/data/tmdb/tmdb_failure.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/domain/media/season_metadata.dart';
import 'package:mochi_player/features/library/metadata/application/metadata_source.dart';

class TmdbMetadataSource implements MetadataSource {
  TmdbMetadataSource({required TmdbApi api}) : _api = api;

  final TmdbApi _api;

  @override
  bool get isConfigured => _api.isConfigured;

  @override
  Future<Movie?> fetchMovieById(String id) => _request(() => _api.fetchMovieById(int.parse(id)));

  @override
  Future<TVShow?> fetchTVShowById(String id) => _request(() => _api.fetchTVShowById(int.parse(id)));

  @override
  Future<Movie?> searchMovie(String title, {int? year}) => _request(() => _api.fetchMovie(title, year: year));

  @override
  Future<TVShow?> searchTVShow(String title, {int? year}) => _request(() => _api.fetchTVShow(title, year: year));

  @override
  Future<SeasonMetadata?> fetchSeason(String showId, int seasonNumber) =>
      _request(() => _api.fetchSeason(int.parse(showId), seasonNumber, showTmdbId: showId));

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
