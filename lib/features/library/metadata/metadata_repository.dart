import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/domain/media/season_metadata.dart';

/// Reads local metadata and atomically imports metadata with file associations.
abstract interface class MetadataRepository {
  Future<Movie?> findMovie(String id);
  Future<TVShow?> findTVShow(String id);

  /// Returns whether the title is newly imported.
  Future<bool> importMovie(Movie movie, MediaFile file);
  Future<bool> importTVShow(TVShow show);

  /// Returns storage keys of files confirmed against an exact episode.
  Future<Set<String>> importSeasonEpisodes(SeasonMetadata metadata, String showId, List<MediaFile> files);

  Future<void> markUnmatched(List<MediaFile> files);
}
