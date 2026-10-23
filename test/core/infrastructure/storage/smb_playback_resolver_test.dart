import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/media/media_type.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/infrastructure/storage/smb_playback_resolver.dart';

import 'smb_media_reader_fake.dart';

void main() {
  const source = StorageSource(
    id: 'nas',
    name: '家庭 NAS',
    type: StorageSourceType.smb,
    endpoint: 'smb://192.168.1.20/Media',
    rootPath: '/Movies',
  );

  test('SMB credentials stay in the reader and never reach the playback URL', () async {
    final reader = MemorySmbReader(Uint8List.fromList([1, 2, 3]));
    final resolver = SmbPlaybackResolver(
      source: source,
      credentials: const StorageCredentials(username: 'mochi', password: 'secret'),
      openReader: (location, credentials, path) async {
        expect(location.resolve(path), 'Movies/Drama/Example.mkv');
        expect(credentials?.username, 'mochi');
        expect(credentials?.password, 'secret');
        return reader;
      },
    );
    final target = (await resolver.resolve(_file))!;
    addTearDown(target.release);
    final uri = Uri.parse(target.url);
    expect(uri.scheme, 'http');
    expect(uri.host, '127.0.0.1');
    expect(uri.userInfo, isEmpty);
    expect(target.url, isNot(contains('secret')));
    expect(target.url, isNot(contains('192.168.1.20')));
    expect(target.httpHeaders, isEmpty);
    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    final response = await (await client.getUrl(uri)).close();
    expect(await response.expand((chunk) => chunk).toList(), [1, 2, 3]);
    await target.release();
    await target.release();
    expect(reader.closeCalls, 1);
  });

  test('does not open a reader for another source', () async {
    final resolver = SmbPlaybackResolver(
      source: const StorageSource(id: 'other', name: 'Other', type: StorageSourceType.smb, endpoint: 'smb://nas/Media'),
      openReader: (_, _, _) async => throw StateError('must not connect'),
    );
    expect(await resolver.resolve(_file), isNull);
  });
}

final _file = MediaFile(
  id: 1,
  sourceId: 'nas',
  path: '/Drama/Example.mkv',
  fileName: 'Example.mkv',
  parsedTitle: 'Example',
  mediaType: MediaType.movie,
  size: 5,
  addedAt: DateTime(2026),
);
