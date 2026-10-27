// 【业务规则】按显式 ID、已有 ID、标题与年份选择元数据。
// 候选与搜索规则在 domain；请求失败不等同于未匹配。

import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/domain/media/season_metadata.dart';
import 'package:mochi_player/features/library/metadata/application/metadata_repository.dart';
import 'package:mochi_player/features/library/metadata/application/metadata_source.dart';
import 'package:mochi_player/features/library/metadata/domain/metadata_match.dart';
import 'package:mochi_player/features/library/metadata/domain/scrape_candidate.dart';
import 'package:mochi_player/features/library/metadata/domain/scrape_search_plan.dart';

/// 先解析显式或已有 ID，再按计划搜索标题；元数据导入由仓库负责，不混入匹配规则。
class MetadataMatcher {
  MetadataMatcher({required MetadataSource source, required MetadataRepository repository})
    : _source = source,
      _repository = repository;

  final MetadataSource _source;
  final MetadataRepository _repository;

  bool get isConfigured => _source.isConfigured;

  Future<SeasonMetadata?> fetchSeason(String showId, int seasonNumber) => _source.fetchSeason(showId, seasonNumber);

  Future<MetadataMatch<Movie>> resolveMovie(ScrapeCandidate candidate) async {
    final knownId = candidate.numericExplicitTmdbId ?? candidate.movieTmdbId;
    if (knownId != null) {
      final local = await _repository.findMovie(knownId);
      if (local != null) {
        return MetadataMatch.confirmed(local, source: MetadataMatchSource.localId);
      }
      final remote = await _source.fetchMovieById(knownId);
      if (remote != null) {
        return MetadataMatch.confirmed(
          remote,
          source: candidate.numericExplicitTmdbId != null
              ? MetadataMatchSource.explicitId
              : MetadataMatchSource.localId,
        );
      }
    }

    final searched = await _searchMovieCandidates(candidate);
    if (searched != null) {
      return searched;
    }
    return const MetadataMatch.unmatched();
  }

  Future<MetadataMatch<TVShow>> resolveTVShow(ScrapeCandidate candidate) async {
    final knownShowId = candidate.numericExplicitTmdbId ?? candidate.tvShowTmdbId;
    if (knownShowId != null) {
      final local = await _repository.findTVShow(knownShowId);
      if (local != null) {
        return MetadataMatch.confirmed(local, source: MetadataMatchSource.localId);
      }
      final remote = await _source.fetchTVShowById(knownShowId);
      if (remote != null) {
        return MetadataMatch.confirmed(remote, source: MetadataMatchSource.explicitId);
      }
    }

    final searched = await _searchTVShowCandidates(candidate);
    if (searched != null) {
      return searched;
    }
    return const MetadataMatch.unmatched();
  }

  Future<MetadataMatch<Movie>?> _searchMovieCandidates(ScrapeCandidate candidate) async {
    for (final attempt in ScrapeSearchPlan.forCandidate(candidate).attempts) {
      final remote = await _source.searchMovie(attempt.query, year: attempt.year);
      if (remote != null) {
        return MetadataMatch.confirmed(remote, source: MetadataMatchSource.titleSearch, query: attempt.query);
      }
    }
    return null;
  }

  Future<MetadataMatch<TVShow>?> _searchTVShowCandidates(ScrapeCandidate candidate) async {
    for (final attempt in ScrapeSearchPlan.forCandidate(candidate).attempts) {
      final remote = await _source.searchTVShow(attempt.query, year: attempt.year);
      if (remote != null) {
        return MetadataMatch.confirmed(remote, source: MetadataMatchSource.titleSearch, query: attempt.query);
      }
    }
    return null;
  }
}
