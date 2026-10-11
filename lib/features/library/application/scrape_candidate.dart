import 'package:mochi_player/core/domain/media/models.dart';

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
    required this.episodeTmdbId,
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
      episodeTmdbId: file.episodeTmdbId,
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
  final String? episodeTmdbId;

  bool get isMovie => kind == ScrapeCandidateKind.movie;

  bool get isEpisode => kind == ScrapeCandidateKind.episode;

  String? get numericExplicitTmdbId {
    final value = explicitTmdbId;
    return value != null && RegExp(r'^\d+$').hasMatch(value) ? value : null;
  }
}

enum ScrapeCandidateKind { movie, episode, unknown }
