import 'package:mochi_player/core/domain/media/episode.dart';

/// 季 Domain Model
class Season {
  final String tvShowTmdbId;
  final int seasonNumber;
  final String title;
  final String? posterUrl;
  final String? overview;
  final int? numberOfEpisodes;
  final List<Episode> episodes;

  const Season({
    required this.tvShowTmdbId,
    required this.seasonNumber,
    required this.title,
    this.posterUrl,
    this.overview,
    this.numberOfEpisodes,
    this.episodes = const [],
  });

  Season withEpisodes(List<Episode> episodes) => Season(
    tvShowTmdbId: tvShowTmdbId,
    seasonNumber: seasonNumber,
    title: title,
    posterUrl: posterUrl,
    overview: overview,
    numberOfEpisodes: numberOfEpisodes,
    episodes: List.unmodifiable(episodes),
  );
}
