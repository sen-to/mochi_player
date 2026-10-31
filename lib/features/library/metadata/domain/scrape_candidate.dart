// 【匹配候选】围绕一个不可变媒体文件提供匹配所需字段和标识规则。
// 文件是唯一数据来源，不复制标题或关联字段，不进行外部格式转换。

import 'package:mochi_player/core/domain/media/models.dart';

class ScrapeCandidate {
  const ScrapeCandidate({required this.file});

  final MediaFile file;

  String get title => file.parsedTitle;
  int? get year => file.parsedYear;
  int? get seasonNumber => file.parsedSeason;
  int? get episodeNumber => file.parsedEpisode;
  String? get explicitTmdbId => file.explicitTmdbId;
  String? get movieTmdbId => file.movieTmdbId;
  String? get tvShowTmdbId => file.tvShowTmdbId;
  String? get episodeKey => file.episodeKey;
  bool get isMovie => file.mediaType == MediaType.movie;
  bool get isEpisode => file.mediaType == MediaType.episode;

  /// 显式 ID 只接受完整数字，其他解析结果不能作为服务商资源 ID。
  String? get numericExplicitTmdbId {
    final value = explicitTmdbId;
    return value != null && RegExp(r'^\d+$').hasMatch(value) ? value : null;
  }
}
