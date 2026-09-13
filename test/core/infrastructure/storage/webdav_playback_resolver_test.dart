import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/infrastructure/storage/webdav_playback_resolver.dart';

MediaFile _file({required String sourceId, required String path}) => MediaFile(
  id: 1,
  sourceId: sourceId,
  path: path,
  fileName: path.split('/').last,
  parsedTitle: 'Example',
  addedAt: DateTime(2026),
);

void main() {
  final source = StorageSource(
    id: 'home-nas',
    name: '家庭 NAS',
    type: StorageSourceType.webDav,
    endpoint: 'https://nas.example.com/webdav',
    rootPath: '/Media',
  );

  test('builds a WebDAV playback URL and Basic authentication header', () async {
    final resolver = WebDavPlaybackResolver(
      source: source,
      credentials: const StorageCredentials(username: 'user', password: 'pass'),
    );

    final target = await resolver.resolve(_file(sourceId: source.id, path: '/Movies/Example.mkv'));

    expect(target?.url, 'https://nas.example.com/webdav/Media/Movies/Example.mkv');
    expect(target?.httpHeaders, {'Authorization': 'Basic dXNlcjpwYXNz'});
  });

  test('does not resolve a file belonging to another source', () async {
    final resolver = WebDavPlaybackResolver(source: source);

    final target = await resolver.resolve(_file(sourceId: 'another-source', path: '/Movies/Example.mkv'));

    expect(target, isNull);
  });
}
