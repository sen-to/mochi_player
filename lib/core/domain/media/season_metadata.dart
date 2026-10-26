import 'package:mochi_player/core/domain/media/episode.dart';
import 'package:mochi_player/core/domain/media/season.dart';

/// One provider season and its available episodes, ready for atomic import.
class SeasonMetadata {
  const SeasonMetadata({required this.season, required this.episodes});

  final Season season;
  final List<Episode> episodes;
}
