import 'package:mochi_player/core/domain/media/artist.dart';

/// 单集 Domain Model
class Episode {
  final String tvShowTmdbId;
  final int seasonNumber;

  /// Actual provider ID, distinct from the stable show/season/episode key.
  final String? tmdbId;
  final int episodeNumber;
  final String title;
  final DateTime? airDate;
  final String? overview;
  final String? stillUrl;
  final List<Artist> guestStars;

  const Episode({
    required this.tvShowTmdbId,
    required this.seasonNumber,
    this.tmdbId,
    required this.episodeNumber,
    required this.title,
    this.airDate,
    this.overview,
    this.stillUrl,
    this.guestStars = const [],
  });

  String get episodeKey => '${tvShowTmdbId}_s${seasonNumber}e$episodeNumber';
}
