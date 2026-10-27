// 【外部能力契约】定义匹配流程需要的电影、剧集与季集读取。
// 空值只表示成功请求无结果，请求失败使用明确的失败类型。

import 'package:mochi_player/core/domain/app_failure.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/domain/media/season_metadata.dart';

/// 匹配所需的元数据操作；空值表示请求成功但没有结果。
abstract interface class MetadataSource {
  bool get isConfigured;

  Future<Movie?> fetchMovieById(String id);
  Future<TVShow?> fetchTVShowById(String id);
  Future<Movie?> searchMovie(String title, {int? year});
  Future<TVShow?> searchTVShow(String title, {int? year});
  Future<SeasonMetadata?> fetchSeason(String showId, int seasonNumber);
}

/// 可供业务处理的请求失败，不向编排暴露后端异常类型。
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
