import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/domain/media/season_metadata.dart';
import 'package:mochi_player/features/library/application/metadata_repository.dart';
import 'package:mochi_player/features/library/application/metadata_source.dart';
import 'package:mochi_player/features/library/application/scrape_candidate.dart';
import 'package:mochi_player/features/library/application/scrape_plan.dart';

/// Resolves explicit/local IDs before trying ordered title searches.
/// Metadata imports belong to the repository, not this matching policy.
class MetadataMatchResolver {
  MetadataMatchResolver({
    required MetadataSource source,
    required MetadataRepository repository,
    ScrapePlanFactory? planFactory,
  }) : _source = source,
       _repository = repository,
       _planFactory = planFactory ?? const ScrapePlanFactory();

  final MetadataSource _source;
  final MetadataRepository _repository;
  final ScrapePlanFactory _planFactory;

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
    for (final attempt in _planFactory.createTitleSearchPlan(candidate).attempts) {
      final remote = await _source.searchMovie(attempt.query, year: attempt.year);
      if (remote != null) {
        return MetadataMatch.confirmed(remote, source: MetadataMatchSource.titleSearch, query: attempt.query);
      }
    }
    return null;
  }

  Future<MetadataMatch<TVShow>?> _searchTVShowCandidates(ScrapeCandidate candidate) async {
    for (final attempt in _planFactory.createTitleSearchPlan(candidate).attempts) {
      final remote = await _source.searchTVShow(attempt.query, year: attempt.year);
      if (remote != null) {
        return MetadataMatch.confirmed(remote, source: MetadataMatchSource.titleSearch, query: attempt.query);
      }
    }
    return null;
  }
}

class MetadataMatch<T> {
  const MetadataMatch._({required this.status, this.metadata, this.source, this.query});

  const MetadataMatch.unmatched() : this._(status: MetadataMatchStatus.unmatched);

  factory MetadataMatch.confirmed(T metadata, {required MetadataMatchSource source, String? query}) =>
      MetadataMatch._(status: MetadataMatchStatus.confirmed, metadata: metadata, source: source, query: query);

  final MetadataMatchStatus status;
  final T? metadata;
  final MetadataMatchSource? source;
  final String? query;

  bool get isConfirmed => status == MetadataMatchStatus.confirmed;
}

enum MetadataMatchSource { localId, explicitId, titleSearch }
