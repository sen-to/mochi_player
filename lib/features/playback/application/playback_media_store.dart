import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/infrastructure/database/database_service.dart';

/// The small persistent surface a player session needs from the media library.
///
/// Keeping this separate lets a dedicated player window load only its queue
/// instead of materializing the complete library catalog and its metadata.
abstract interface class PlaybackMediaStore {
  Future<MediaFile?> readMediaFile({required String sourceId, required String path});

  Future<void> updateProgress(MediaFile file, int position, {int? duration});
}

class DatabasePlaybackMediaStore implements PlaybackMediaStore {
  DatabasePlaybackMediaStore({DatabaseService? database}) : _database = database ?? DatabaseService();

  final DatabaseService _database;
  @override
  Future<MediaFile?> readMediaFile({required String sourceId, required String path}) =>
      _database.getMediaFile(sourceId, path);

  @override
  Future<void> updateProgress(MediaFile file, int position, {int? duration}) async {
    final row = await _database.getMediaFile(file.sourceId, file.path);
    if (row == null) return;
    await _database.updateProgress(row, position, duration: duration);
  }
}
