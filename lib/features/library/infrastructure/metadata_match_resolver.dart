import 'package:mochi_player/core/infrastructure/database/database_service.dart';
import 'package:mochi_player/core/infrastructure/database/entities/entities.dart';
import 'package:mochi_player/core/infrastructure/tmdb/tmdb_season_result.dart';
import 'package:mochi_player/core/infrastructure/tmdb/tmdb_service.dart';
import 'package:mochi_player/features/library/application/scrape_candidate.dart';
import 'package:mochi_player/features/library/application/scrape_plan.dart';

/// Resolves parsed local media into a single, confidence-checked TMDB match.
/// Persistence of fetched metadata belongs to the importer, not this class.
class MetadataMatchResolver {
  MetadataMatchResolver({TmdbService? tmdb, DatabaseService? database, ScrapePlanFactory? planFactory})
    : _tmdb = tmdb ?? TmdbService(),
      _database = database ?? DatabaseService(),
      _planFactory = planFactory ?? const ScrapePlanFactory();

  final TmdbService _tmdb;
  final DatabaseService _database;
  final ScrapePlanFactory _planFactory;

  bool get isConfigured => _tmdb.isConfigured;

  Future<TmdbSeasonResult?> fetchSeason(int tvId, int seasonNumber, {required String showTmdbId}) =>
      _tmdb.fetchSeason(tvId, seasonNumber, showTmdbId: showTmdbId);

  Future<MetadataMatch<MovieMetadataEntity>> resolveMovie(ScrapeCandidate candidate) async {
    final knownId = candidate.movieTmdbId ?? candidate.numericExplicitTmdbId;
    if (knownId != null) {
      final local = await _database.getMovieByTmdbId(knownId);
      if (local != null) {
        return MetadataMatch.confirmed(local, source: MetadataMatchSource.localId);
      }
      final remote = await _tmdb.fetchMovieById(int.parse(knownId));
      if (remote != null) {
        return MetadataMatch.confirmed(
          remote,
          source: candidate.movieTmdbId != null ? MetadataMatchSource.localId : MetadataMatchSource.explicitId,
        );
      }
    }

    final searched = await _searchMovieCandidates(candidate);
    if (searched != null) {
      return searched;
    }
    return const MetadataMatch.unmatched();
  }

  Future<MetadataMatch<TVShowMetadataEntity>> resolveTVShow(ScrapeCandidate candidate) async {
    final knownShowId = candidate.tvShowTmdbId ?? candidate.numericExplicitTmdbId;
    if (knownShowId != null) {
      final local = await _database.getTVShowByTmdbId(knownShowId);
      if (local != null) {
        return MetadataMatch.confirmed(local, source: MetadataMatchSource.localId);
      }
      final remote = await _tmdb.fetchTVShowById(int.parse(knownShowId));
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

  Future<MetadataMatch<MovieMetadataEntity>?> _searchMovieCandidates(ScrapeCandidate candidate) async {
    for (final attempt in _planFactory.createTitleSearchPlan(candidate).attempts) {
      final remote = await _tmdb.fetchMovie(attempt.query, year: attempt.year);
      if (remote != null) {
        return MetadataMatch.confirmed(remote, source: MetadataMatchSource.titleSearch, query: attempt.query);
      }
    }
    return null;
  }

  Future<MetadataMatch<TVShowMetadataEntity>?> _searchTVShowCandidates(ScrapeCandidate candidate) async {
    for (final attempt in _planFactory.createTitleSearchPlan(candidate).attempts) {
      final remote = await _tmdb.fetchTVShow(attempt.query, year: attempt.year);
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

enum MetadataMatchStatus { confirmed, unmatched }

enum MetadataMatchSource { localId, explicitId, titleSearch }
