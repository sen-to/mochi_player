import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/media/media_file_kind.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/infrastructure/storage/storage_provider_registry.dart';
import 'package:mochi_player/features/library/application/file_browser_provider.dart';

void main() {
  test('maps source directory entries without borrowing playback metadata', () async {
    final modifiedAt = DateTime(2026, 7, 31, 12, 30);
    final provider = _provider(
      (_) async => [
        const StorageEntry(name: '.hidden', isDirectory: false, size: 0, modifiedAt: null),
        StorageEntry(name: 'Movies', isDirectory: true, size: 0, modifiedAt: modifiedAt),
        StorageEntry(name: 'episode.mp4', isDirectory: false, size: 2048, modifiedAt: modifiedAt),
        const StorageEntry(name: 'theme.flac', isDirectory: false, size: 1024, modifiedAt: null),
        const StorageEntry(name: 'notes.txt', isDirectory: false, size: 12, modifiedAt: null),
      ],
    );

    await provider.openStorageSource(_source, null);

    expect(provider.items.map((item) => item.name), ['Movies', 'episode.mp4', 'theme.flac', 'notes.txt']);
    expect(provider.items[0].kind, MediaFileKind.directory);
    expect(provider.items[1].kind, MediaFileKind.video);
    expect(provider.items[1].modifiedAt, modifiedAt);
    expect(provider.items[1].sourceId, _source.id);
    expect(provider.createPlaybackFile(provider.items[1]).sourceId, _source.id);
    expect(provider.items[2].kind, MediaFileKind.other);
    expect(provider.items[2].isPlayable, isFalse);
    expect(provider.items[3].kind, MediaFileKind.other);
  });

  test('ignores a stale directory response', () async {
    final first = Completer<List<StorageEntry>>();
    final second = Completer<List<StorageEntry>>();
    final provider = _provider((path) {
      if (path == '/first') return first.future;
      if (path == '/second') return second.future;
      return Future.value(const []);
    });
    await provider.openStorageSource(_source, null);

    final firstRequest = provider.fetchFiles('/first');
    final secondRequest = provider.fetchFiles('/second');
    second.complete(const [StorageEntry(name: 'new.mp4', isDirectory: false, size: 0, modifiedAt: null)]);
    await secondRequest;
    first.complete(const [StorageEntry(name: 'stale.mp4', isDirectory: false, size: 0, modifiedAt: null)]);
    await firstRequest;

    expect(provider.currentPath, '/second');
    expect(provider.items.single.name, 'new.mp4');
    expect(provider.isLoading, isFalse);
  });

  test('goes to the parent directory instead of navigation history', () async {
    final provider = _provider((_) async => const []);
    await provider.openStorageSource(_source, null);

    await provider.fetchFiles('/quark/来自分享/');
    provider.navigateBack();
    await Future<void>.delayed(Duration.zero);

    expect(provider.currentPath, '/quark/');
    provider.navigateBack();
    await Future<void>.delayed(Duration.zero);
    expect(provider.currentPath, '/');
    expect(provider.canGoBack, isFalse);
  });

  test('closes the previous storage connection when changing sources', () async {
    final storageProvider = _TrackingStorageProvider();
    final provider = FileBrowserProvider(storageProviderRegistry: StorageProviderRegistry([storageProvider]));

    await provider.openStorageSource(_source, null);
    final firstConnection = storageProvider.connections.single;
    await provider.openStorageSource(_source, null);

    expect(firstConnection.isClosed, isTrue);
    expect(storageProvider.connections, hasLength(2));
  });
}

const _source = StorageSource(
  id: 'home-nas',
  name: '家庭媒体库',
  type: StorageSourceType.webDav,
  endpoint: 'https://example.com/dav',
);

FileBrowserProvider _provider(Future<List<StorageEntry>> Function(String path) read) =>
    FileBrowserProvider(storageProviderRegistry: StorageProviderRegistry([_FakeStorageProvider(read)]));

class _FakeStorageProvider implements StorageProvider {
  const _FakeStorageProvider(this._read);

  final Future<List<StorageEntry>> Function(String path) _read;

  @override
  StorageSourceType get type => StorageSourceType.webDav;

  @override
  Future<StorageConnection> connect(StorageSource source, StorageCredentials? credentials) async =>
      _FakeStorageConnection(source, _read);
}

class _FakeStorageConnection implements StorageConnection {
  const _FakeStorageConnection(this.source, this._read);

  @override
  final StorageSource source;
  final Future<List<StorageEntry>> Function(String path) _read;

  @override
  Future<List<StorageEntry>> readDirectory(String path) => _read(path);

  @override
  Future<bool> testConnection() async => true;

  @override
  Future<void> close() async {}
}

class _TrackingStorageProvider implements StorageProvider {
  final connections = <_TrackingStorageConnection>[];

  @override
  StorageSourceType get type => StorageSourceType.webDav;

  @override
  Future<StorageConnection> connect(StorageSource source, StorageCredentials? credentials) async {
    final connection = _TrackingStorageConnection(source);
    connections.add(connection);
    return connection;
  }
}

class _TrackingStorageConnection implements StorageConnection {
  _TrackingStorageConnection(this.source);

  @override
  final StorageSource source;
  bool isClosed = false;

  @override
  Future<void> close() async {
    isClosed = true;
  }

  @override
  Future<List<StorageEntry>> readDirectory(String path) async => const [];

  @override
  Future<bool> testConnection() async => true;
}
