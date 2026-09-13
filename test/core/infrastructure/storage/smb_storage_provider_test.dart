import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/infrastructure/storage/smb_source_location.dart';
import 'package:mochi_player/core/infrastructure/storage/smb_storage_provider.dart';

void main() {
  const source = StorageSource(
    id: 'nas',
    name: '家庭 NAS',
    type: StorageSourceType.smb,
    endpoint: 'smb://192.168.1.20/Media',
    rootPath: '/电影',
  );

  test('maps the configured SMB root and directory entries', () async {
    String? requestedPath;
    final provider = SmbStorageProvider(
      connect: (location, credentials) async {
        expect(location.host, '192.168.1.20');
        expect(location.share, 'Media');
        expect(credentials, const StorageCredentials(username: 'mochi', password: 'secret'));
        return _FakeClient((path) async {
          requestedPath = path;
          return [
            SmbDirectoryEntry(name: '电影', isDirectory: true, isFile: false, size: 0, modifiedAt: DateTime(2026)),
            SmbDirectoryEntry(
              name: 'movie.mkv',
              isDirectory: false,
              isFile: true,
              size: 1024,
              modifiedAt: DateTime(2026),
            ),
          ];
        });
      },
    );

    final connection = await provider.connect(source, const StorageCredentials(username: 'mochi', password: 'secret'));
    final entries = await connection.readDirectory('/');

    expect(requestedPath, '电影');
    expect(entries.map((entry) => entry.name), ['电影', 'movie.mkv']);
    expect(entries.last.size, 1024);
  });

  test('keeps source-relative paths inside the configured SMB root', () {
    final location = SmbSourceLocation.fromSource(source);

    expect(location.resolve('/Series/'), '电影/Series');
    expect(location.resolve('/'), '电影');
  });
}

class _FakeClient implements SmbDirectoryClient {
  const _FakeClient(this._read);

  final Future<List<SmbDirectoryEntry>> Function(String path) _read;

  @override
  Future<List<SmbDirectoryEntry>> readDirectory(String path) => _read(path);

  @override
  Future<void> close() async {}
}
