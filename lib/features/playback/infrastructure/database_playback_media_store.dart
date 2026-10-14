import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/infrastructure/database/database_service.dart';
import 'package:mochi_player/features/playback/application/playback_media_store.dart';

class DatabasePlaybackMediaStore implements PlaybackMediaStore {
  DatabasePlaybackMediaStore({required DatabaseService database}) : _database = database;

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
