import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:uuid/uuid.dart';

class PlayerWindowRequest {
  PlayerWindowRequest.fromPlayback({
    required this.initialMedia,
    required List<MediaFile> queue,
    this.contextTitle,
    String? requestId,
  }) : requestId = requestId ?? const Uuid().v4(),
       queue = List.unmodifiable(queue);

  final String requestId;
  final MediaFile initialMedia;
  final List<MediaFile> queue;
  final String? contextTitle;
}
