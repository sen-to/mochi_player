import 'dart:convert';

import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:uuid/uuid.dart';

/// A serializable reference to a media file stored in the local catalog.
///
/// A player window must re-read this reference from its own database
/// connection. It intentionally never carries resolved URLs, credentials, or
/// live provider instances across Flutter engines.
class PlayerWindowMediaRef {
  const PlayerWindowMediaRef({required this.sourceId, required this.path});

  final String sourceId;
  final String path;

  factory PlayerWindowMediaRef.fromMediaFile(MediaFile file) =>
      PlayerWindowMediaRef(sourceId: file.sourceId, path: file.path);

  factory PlayerWindowMediaRef.fromJson(Map<String, Object?> json) {
    final sourceId = json['sourceId'];
    final path = json['path'];
    if (sourceId is! String || sourceId.isEmpty || path is! String || path.isEmpty) {
      throw const FormatException('A player-window media reference requires sourceId and path.');
    }
    return PlayerWindowMediaRef(sourceId: sourceId, path: path);
  }

  Map<String, Object> toJson() => {'sourceId': sourceId, 'path': path};

  @override
  bool operator ==(Object other) => other is PlayerWindowMediaRef && other.sourceId == sourceId && other.path == path;

  @override
  int get hashCode => Object.hash(sourceId, path);
}

/// The stable launch contract between the library window and a player window.
class PlayerWindowRequest {
  static const protocol = 'mochi-player/player-window';
  static const protocolVersion = 1;

  const PlayerWindowRequest({
    required this.requestId,
    required this.initialMedia,
    required this.queue,
    this.contextTitle,
    this.version = protocolVersion,
  });

  factory PlayerWindowRequest.fromPlayback({
    required MediaFile initialMedia,
    required List<MediaFile> queue,
    String? contextTitle,
    String? requestId,
  }) => PlayerWindowRequest(
    requestId: requestId ?? const Uuid().v4(),
    initialMedia: PlayerWindowMediaRef.fromMediaFile(initialMedia),
    queue: queue.map(PlayerWindowMediaRef.fromMediaFile).toList(growable: false),
    contextTitle: contextTitle,
  );

  final String requestId;
  final PlayerWindowMediaRef initialMedia;
  final List<PlayerWindowMediaRef> queue;
  final String? contextTitle;
  final int version;

  /// The string accepted by desktop_multi_window as the child-engine argument.
  String encode() => jsonEncode(toJson());

  Map<String, Object?> toJson() => {
    'protocol': protocol,
    'version': version,
    'requestId': requestId,
    'initialMedia': initialMedia.toJson(),
    'queue': queue.map((item) => item.toJson()).toList(growable: false),
    if (contextTitle != null) 'contextTitle': contextTitle,
  };

  static PlayerWindowRequest? tryDecode(String arguments) {
    try {
      final decoded = jsonDecode(arguments);
      if (decoded is! Map) return null;
      final json = Map<String, Object?>.from(decoded);
      if (json['protocol'] != protocol || json['version'] != protocolVersion) {
        return null;
      }
      final requestId = json['requestId'];
      final initialMedia = json['initialMedia'];
      final queue = json['queue'];
      if (requestId is! String || requestId.isEmpty || initialMedia is! Map || queue is! List) {
        return null;
      }
      return PlayerWindowRequest(
        requestId: requestId,
        initialMedia: PlayerWindowMediaRef.fromJson(Map<String, Object?>.from(initialMedia)),
        queue: queue
            .map((item) => PlayerWindowMediaRef.fromJson(Map<String, Object?>.from(item as Map)))
            .toList(growable: false),
        contextTitle: json['contextTitle'] is String ? json['contextTitle'] as String : null,
      );
    } on Object {
      return null;
    }
  }
}
