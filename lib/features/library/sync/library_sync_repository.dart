import 'package:mochi_player/core/domain/media/media_file.dart';

/// Persistence needed by synchronization; transaction details stay in the adapter.
abstract interface class LibrarySyncRepository {
  Future<Set<String>> sourcePaths(String sourceId);

  /// Updates discovery attributes without overwriting matches or user state.
  Future<void> saveScannedFiles(List<MediaFile> files);

  /// Call only after a complete, uninterrupted scan of the source.
  Future<int> removeMissingFiles(String sourceId, Set<String> seen);

  Future<List<MediaFile>> scrapeCandidates();
}
