import 'package:mochi_player/core/domain/media/media_file.dart';

/// The small persistent surface a player session needs from the media library.
///
/// Keeping this separate lets a dedicated player window load only its queue
/// instead of materializing the complete library catalog and its metadata.
abstract interface class PlaybackMediaStore {
  Future<MediaFile?> readMediaFile({required String sourceId, required String path});

  Future<void> updateProgress(MediaFile file, int position, {int? duration});
}
