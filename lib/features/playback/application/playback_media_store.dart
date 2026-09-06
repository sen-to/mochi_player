import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/infrastructure/database/database_service.dart';
import 'package:mochi_player/core/infrastructure/database/media_entity_mapper.dart';

/// The small persistent surface a player session needs from the media library.
///
/// Keeping this separate lets a dedicated player window load only its queue
/// instead of materializing the complete library catalog and its metadata.
abstract interface class PlaybackMediaStore {
  Future<MediaFile?> readMediaFile({required String sourceId, required String path});

  Future<void> updateProgress(MediaFile file, int position, {int? duration});

  Iterable<PlaybackMediaKey> get changedMedia;
}

class PlaybackMediaKey {
  const PlaybackMediaKey({required this.sourceId, required this.path});

  final String sourceId;
  final String path;

  Map<String, String> toJson() => {'sourceId': sourceId, 'path': path};

  static PlaybackMediaKey? tryParse(Object? value) {
    if (value is! Map) return null;
    final sourceId = value['sourceId'];
    final path = value['path'];
    if (sourceId is! String || sourceId.isEmpty || path is! String || path.isEmpty) {
      return null;
    }
    return PlaybackMediaKey(sourceId: sourceId, path: path);
  }

  @override
  bool operator ==(Object other) => other is PlaybackMediaKey && other.sourceId == sourceId && other.path == path;

  @override
  int get hashCode => Object.hash(sourceId, path);
}

class DatabasePlaybackMediaStore implements PlaybackMediaStore {
  DatabasePlaybackMediaStore({DatabaseService? database}) : _database = database ?? DatabaseService();

  final DatabaseService _database;
  final Set<PlaybackMediaKey> _changedMedia = {};

  @override
  Iterable<PlaybackMediaKey> get changedMedia => _changedMedia;

  @override
  Future<MediaFile?> readMediaFile({required String sourceId, required String path}) async {
    final entity = await _database.getMediaFile(sourceId, path);
    return entity == null ? null : MediaEntityMapper.toMediaFile(entity);
  }

  @override
  Future<void> updateProgress(MediaFile file, int position, {int? duration}) async {
    final entity = await _database.getMediaFile(file.sourceId, file.path);
    if (entity == null) return;
    await _database.updateProgress(entity, position, duration: duration);
    _changedMedia.add(PlaybackMediaKey(sourceId: file.sourceId, path: file.path));
  }
}
