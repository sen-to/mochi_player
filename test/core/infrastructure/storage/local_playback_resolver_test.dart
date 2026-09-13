import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/media/media_type.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/infrastructure/storage/local_playback_resolver.dart';

void main() {
  const source = StorageSource(
    id: 'local-media',
    name: '本地媒体',
    type: StorageSourceType.local,
    endpoint: '/Users/test/Movies',
  );

  test('resolves a source-relative file to a file URL', () async {
    final target = await LocalPlaybackResolver(source: source).resolve(
      MediaFile(
        id: 1,
        sourceId: 'local-media',
        path: '/Drama/Example.mkv',
        fileName: 'Example.mkv',
        parsedTitle: 'Example',
        mediaType: MediaType.movie,
        addedAt: DateTime(2026),
      ),
    );

    expect(target?.url, File('/Users/test/Movies/Drama/Example.mkv').uri.toString());
    expect(target?.httpHeaders, isEmpty);
  });
}
