import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/features/playback/domain/player_window_request.dart';

MediaFile _file(int id, String path) => MediaFile(
  id: id,
  sourceId: 'source-$id',
  path: path,
  fileName: path.split('/').last,
  parsedTitle: 'Show',
  addedAt: DateTime(2026),
);

void main() {
  test(
    'serializes only durable media references for a child player window',
    () {
      final request = PlayerWindowRequest.fromPlayback(
        initialMedia: _file(1, 'season-1/episode-1.mkv'),
        queue: [
          _file(1, 'season-1/episode-1.mkv'),
          _file(2, 'season-1/episode-2.mkv'),
        ],
        contextTitle: 'Example show',
        requestId: 'request-123',
      );

      final decoded = jsonDecode(request.encode()) as Map<String, Object?>;

      expect(decoded['protocol'], PlayerWindowRequest.protocol);
      expect(decoded['version'], PlayerWindowRequest.protocolVersion);
      expect(decoded['requestId'], 'request-123');
      expect(decoded['contextTitle'], 'Example show');
      expect(decoded.containsKey('url'), isFalse);
      expect(decoded.containsKey('httpHeaders'), isFalse);
      expect(decoded['initialMedia'], {
        'sourceId': 'source-1',
        'path': 'season-1/episode-1.mkv',
      });
    },
  );

  test('round trips a request and preserves the queue order', () {
    final request = PlayerWindowRequest.fromPlayback(
      initialMedia: _file(1, 'one.mkv'),
      queue: [_file(1, 'one.mkv'), _file(2, 'two.mkv')],
      requestId: 'request-123',
    );

    final decoded = PlayerWindowRequest.tryDecode(request.encode());

    expect(decoded?.requestId, 'request-123');
    expect(
      decoded?.initialMedia,
      const PlayerWindowMediaRef(sourceId: 'source-1', path: 'one.mkv'),
    );
    expect(decoded?.queue, [
      const PlayerWindowMediaRef(sourceId: 'source-1', path: 'one.mkv'),
      const PlayerWindowMediaRef(sourceId: 'source-2', path: 'two.mkv'),
    ]);
  });

  test('rejects unsupported or malformed window arguments', () {
    expect(PlayerWindowRequest.tryDecode('not json'), isNull);
    expect(
      PlayerWindowRequest.tryDecode(
        '{"protocol":"${PlayerWindowRequest.protocol}","version":2}',
      ),
      isNull,
    );
  });
}
