import 'package:mochi_player/core/domain/media/media_file.dart';

typedef PersistPlaybackProgress = Future<void> Function(MediaFile file, int position, {int? duration});

/// Serializes progress writes in request order.
///
/// A player can request a periodic save while a seek, queue transition, or
/// disposal save is already in flight. Keeping these writes ordered prevents a
/// delayed older snapshot from overwriting a newer playback position.
class PlaybackProgressWriter {
  PlaybackProgressWriter(this._persist);

  final PersistPlaybackProgress _persist;
  Future<void> _tail = Future.value();

  Future<void> drain() => _tail;

  Future<void> save(MediaFile file, int position, {int? duration}) {
    final operation = _tail.then((_) => _persist(file, position, duration: duration));

    // Keep the queue usable after a failed database write. The returned future
    // still preserves the failure for the caller to report.
    _tail = operation.catchError((Object _) {});
    return operation;
  }
}
