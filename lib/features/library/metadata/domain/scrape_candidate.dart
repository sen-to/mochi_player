// 【匹配输入模型】保存匹配一个媒体文件所需的结构化信息。
// 只表达候选及显式标识规则，文件到候选的转换由 Mapper 负责。

import 'package:mochi_player/core/domain/media/models.dart';

class ScrapeCandidate {
  const ScrapeCandidate({
    required this.file,
    required this.title,
    required this.year,
    required this.kind,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.explicitTmdbId,
    required this.movieTmdbId,
    required this.tvShowTmdbId,
    required this.episodeKey,
  });

  final MediaFile file;
  final String title;
  final int? year;
  final ScrapeCandidateKind kind;
  final int? seasonNumber;
  final int? episodeNumber;

  /// 网络搜索前，从文件名或路径得到的可选显式 ID。
  final String? explicitTmdbId;
  final String? movieTmdbId;
  final String? tvShowTmdbId;
  final String? episodeKey;

  bool get isMovie => kind == ScrapeCandidateKind.movie;

  bool get isEpisode => kind == ScrapeCandidateKind.episode;

  String? get numericExplicitTmdbId {
    final value = explicitTmdbId;
    return value != null && RegExp(r'^\d+$').hasMatch(value) ? value : null;
  }
}

enum ScrapeCandidateKind { movie, episode, unknown }
