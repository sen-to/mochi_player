import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/features/library/infrastructure/storage_media_scanner.dart';

void main() {
  test('recursively indexes video files with source-relative paths', () async {
    final scanner = StorageMediaScanner(
      _FakeConnection({
        '/': const [
          StorageEntry(name: 'Movies', isDirectory: true, size: 0, modifiedAt: null),
          StorageEntry(name: 'notes.txt', isDirectory: false, size: 12, modifiedAt: null),
        ],
        '/Movies/': const [StorageEntry(name: 'Example.mkv', isDirectory: false, size: 2048, modifiedAt: null)],
      }),
    );

    final files = await scanner.scan().toList();

    expect(files, hasLength(1));
    expect(files.single.sourceId, 'home-nas');
    expect(files.single.path, '/Movies/Example.mkv');
    expect(files.single.storageKey, 'home-nas:/Movies/Example.mkv');
    expect(scanner.hadReadError, isFalse);
  });

  test('marks partial scans as read errors', () async {
    final scanner = StorageMediaScanner(_FakeConnection({'/': const []}, failingPath: '/'));

    expect(await scanner.scan().toList(), isEmpty);
    expect(scanner.hadReadError, isTrue);
  });
}

class _FakeConnection implements StorageConnection {
  _FakeConnection(this._directories, {this.failingPath});

  final Map<String, List<StorageEntry>> _directories;
  final String? failingPath;

  @override
  final source = const StorageSource(
    id: 'home-nas',
    name: '家庭媒体库',
    type: StorageSourceType.webDav,
    endpoint: 'http://127.0.0.1:5244/dav',
  );

  @override
  Future<List<StorageEntry>> readDirectory(String path) async {
    if (path == failingPath) throw StateError('unavailable');
    return _directories[path] ?? const [];
  }

  @override
  Future<bool> testConnection() async => true;

  @override
  Future<void> close() async {}
}
