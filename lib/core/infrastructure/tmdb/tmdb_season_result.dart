import 'package:mochi_player/core/domain/media/models.dart';

class TmdbSeasonResult {
  const TmdbSeasonResult({required this.season, required this.episodes});

  final Season season;
  final List<Episode> episodes;
}
