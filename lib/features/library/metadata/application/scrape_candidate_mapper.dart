// 【业务输入映射】将媒体文件快照转换为元数据匹配候选。
// 不执行匹配或写库，输入模型保持独立于转换实现。

import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/features/library/metadata/domain/scrape_candidate.dart';

abstract final class ScrapeCandidateMapper {
  static ScrapeCandidate fromMediaFile(MediaFile file) {
    return ScrapeCandidate(
      file: file,
      title: file.parsedTitle,
      year: file.parsedYear,
      kind: switch (file.mediaType) {
        MediaType.movie => ScrapeCandidateKind.movie,
        MediaType.episode => ScrapeCandidateKind.episode,
        MediaType.unknown || MediaType.folder => ScrapeCandidateKind.unknown,
      },
      seasonNumber: file.parsedSeason,
      episodeNumber: file.parsedEpisode,
      explicitTmdbId: file.explicitTmdbId,
      movieTmdbId: file.movieTmdbId,
      tvShowTmdbId: file.tvShowTmdbId,
      episodeKey: file.episodeKey,
    );
  }
}
