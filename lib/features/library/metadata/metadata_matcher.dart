import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/domain/media/season_metadata.dart';
import 'package:mochi_player/features/library/metadata/metadata_repository.dart';
import 'package:mochi_player/features/library/metadata/metadata_source.dart';

/// Resolves explicit/local IDs before trying ordered title searches.
/// Metadata imports belong to the repository, not this matching policy.
class MetadataMatcher {
  MetadataMatcher({
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

/// Immutable, structured input for a metadata match.
///
/// A candidate is deliberately separate from [MediaFile]: parsing a file
/// name answers what we know locally, while matching answers whether that
/// information identifies an item at a metadata provider.
class ScrapeCandidate {
  const ScrapeCandidate._({
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

  factory ScrapeCandidate.fromMediaFile(MediaFile file) {
    return ScrapeCandidate._(
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

  final MediaFile file;
  final String title;
  final int? year;
  final ScrapeCandidateKind kind;
  final int? seasonNumber;
  final int? episodeNumber;

  /// Optional explicit ID from the filename/path, before any online search.
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

/// An ordered, observable set of provider requests for one local candidate.
///
/// This is deliberately data-only: it decides neither which provider result
/// wins nor how metadata is written to the database.
class ScrapePlan {
  const ScrapePlan(this.attempts);

  final List<ScrapeSearchAttempt> attempts;
}

class ScrapeSearchAttempt {
  const ScrapeSearchAttempt({required this.query, this.year});

  final String query;
  final int? year;
}

/// The sole home of the automatic title-search rule.
///
/// Rule: search the complete cleaned local title with its parsed year. Only
/// when that request returns no result, retry the same title without a year.
class ScrapePlanFactory {
  const ScrapePlanFactory();

  ScrapePlan createTitleSearchPlan(ScrapeCandidate candidate) {
    final query = candidate.title.trim();
    if (query.isEmpty) return const ScrapePlan([]);

    return ScrapePlan([
      ScrapeSearchAttempt(query: query, year: candidate.year),
      if (candidate.year != null) ScrapeSearchAttempt(query: query),
    ]);
  }
}
