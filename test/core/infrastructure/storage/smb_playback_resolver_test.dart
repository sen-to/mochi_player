import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/media/media_type.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/infrastructure/storage/smb_playback_resolver.dart';

void main() {
  const source = StorageSource(
    id: 'nas',
    name: '家庭 NAS',
    type: StorageSourceType.smb,
    endpoint: 'smb://192.168.1.20/Media',
    rootPath: '/Movies',
  );

  test('returns a directly playable SMB URL without a local cache', () async {
    final target = await const SmbPlaybackResolver(
      source: source,
      credentials: StorageCredentials(username: 'mochi', password: 'secret'),
    ).resolve(_file);

    expect(target?.url, 'smb://mochi:secret@192.168.1.20/Media/Movies/Drama/Example.mkv');
  });

  test('omits SMB credentials when the source is anonymous', () async {
    final target = await const SmbPlaybackResolver(source: source).resolve(_file);

    expect(target?.url, 'smb://192.168.1.20/Media/Movies/Drama/Example.mkv');
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
