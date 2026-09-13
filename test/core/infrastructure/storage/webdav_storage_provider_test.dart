import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/infrastructure/storage/webdav_storage_provider.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;

void main() {
  test('uses the configured WebDAV root without adding an implicit path prefix', () async {
    final client = _FakeWebDavClient([webdav.File(name: 'Movies', isDir: true)]);
    final connection = WebDavStorageConnection(
      source: const StorageSource(
        id: 'nas',
        name: '家庭 NAS',
        type: StorageSourceType.webDav,
        endpoint: 'https://nas.example.com/webdav',
        rootPath: '/Media',
      ),
      client: client,
    );

    final entries = await connection.readDirectory('/movies');

    expect(client.requestedPaths, ['/Media/movies']);
    expect(entries.single.name, 'Movies');
    expect(entries.single.isDirectory, isTrue);
  });

  test('tests the source-relative root directory', () async {
    final client = _FakeWebDavClient(const []);
    final connection = WebDavStorageConnection(
      source: const StorageSource(
        id: 'dav',
        name: 'WebDAV',
        type: StorageSourceType.webDav,
        endpoint: 'https://dav.example.com/root',
      ),
      client: client,
    );

    expect(await connection.testConnection(), isTrue);
    expect(client.requestedPaths, ['/']);
  });
}

class _FakeWebDavClient implements WebDavDirectoryClient {
  final List<webdav.File> _response;
  final List<String> requestedPaths = [];

  _FakeWebDavClient(this._response);

  @override
  Future<List<webdav.File>> readDirectory(String path) async {
    requestedPaths.add(path);
    return _response;
  }
}
