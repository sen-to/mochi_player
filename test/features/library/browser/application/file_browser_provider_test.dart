// 【行为测试】验证维护当前来源、目录、过滤和排序，并协调浏览连接。
// 测试对象的职责边界：协议细节交给存储适配器；来源失效、切换和关闭时释放连接。

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/domain/storage/storage_adapter_registry.dart';
import 'package:mochi_player/features/library/browser/application/file_browser_provider.dart';
import 'package:mochi_player/features/library/domain/media_file_kind.dart';

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

    await provider.openStorageSource(_source);

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
    await provider.openStorageSource(_source);

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
    await provider.openStorageSource(_source);

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
    final storageAdapter = _TrackingStorageAdapter();
    final provider = FileBrowserProvider(
      readCredentials: (_) async => null,
      storageAdapterRegistry: StorageAdapterRegistry([storageAdapter]),
    );

    await provider.openStorageSource(_source);
    final firstConnection = storageAdapter.connections.single;
    await provider.openStorageSource(_source);

    expect(firstConnection.isClosed, isTrue);
    expect(storageAdapter.connections, hasLength(2));
  });
  test('a saved source invalidates its active browser while unrelated changes leave it open', () async {
    final adapter = _TrackingStorageAdapter();
    final provider = FileBrowserProvider(
      readCredentials: (_) async => null,
      storageAdapterRegistry: StorageAdapterRegistry([adapter]),
    );
    addTearDown(provider.dispose);
    await provider.openStorageSource(_source);
    expect(provider.invalidateSource('another-source'), false);
    expect(provider.activeSource, _source);
    expect(provider.invalidateSource(_source.id), true);
    expect(provider.hasSelectedStorageSource, false);
    expect(adapter.connections.single.isClosed, true);
  });

  test('a source changed while reading credentials never creates a connection', () async {
    final credentials = Completer<StorageCredentials?>();
    final adapter = _TrackingStorageAdapter();
    final provider = FileBrowserProvider(
      readCredentials: (_) => credentials.future,
      storageAdapterRegistry: StorageAdapterRegistry([adapter]),
    );
    addTearDown(provider.dispose);
    final opening = provider.openStorageSource(_source);
    expect(provider.invalidateSource(_source.id), true);
    credentials.complete(null);
    await opening;
    expect(adapter.connections, isEmpty);
    expect(provider.hasSelectedStorageSource, false);
  });

  test('a source changed during connection creation closes the stale connection', () async {
    final pending = Completer<StorageConnection>();
    final connection = _TrackingStorageConnection(_source);
    final provider = FileBrowserProvider(
      readCredentials: (_) async => null,
      storageAdapterRegistry: StorageAdapterRegistry([_DelayedProvider(pending.future)]),
    );
    addTearDown(provider.dispose);
    final opening = provider.openStorageSource(_source);
    await Future<void>.delayed(Duration.zero);
    expect(provider.invalidateSource(_source.id), true);
    pending.complete(connection);
    await opening;
    expect(connection.isClosed, true);
    expect(provider.hasSelectedStorageSource, false);
  });

  test('an opening connection that finishes after shutdown is closed and never selected', () async {
    final pending = Completer<StorageConnection>();
    final connection = _TrackingStorageConnection(_source);
    final provider = FileBrowserProvider(
      readCredentials: (_) async => null,
      storageAdapterRegistry: StorageAdapterRegistry([_DelayedProvider(pending.future)]),
    );
    final opening = provider.openStorageSource(_source);
    await Future<void>.delayed(Duration.zero);
    await provider.shutdown();
    pending.complete(connection);
    await opening;
    expect(connection.isClosed, isTrue);
    expect(provider.hasSelectedStorageSource, isFalse);
    provider.dispose();
  });
}

const _source = StorageSource(
  id: 'home-nas',
  name: '家庭媒体库',
  type: StorageSourceType.webDav,
  endpoint: 'https://example.com/dav',
);

FileBrowserProvider _provider(Future<List<StorageEntry>> Function(String path) read) => FileBrowserProvider(
  readCredentials: (_) async => null,
  storageAdapterRegistry: StorageAdapterRegistry([_FakeStorageAdapter(read)]),
);

class _FakeStorageAdapter implements StorageAdapter {
  const _FakeStorageAdapter(this._read);

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
  Future<void> close() async {}
}

class _TrackingStorageAdapter implements StorageAdapter {
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
}

class _DelayedProvider implements StorageAdapter {
  _DelayedProvider(this.pending);
  final Future<StorageConnection> pending;
  @override
  StorageSourceType get type => StorageSourceType.webDav;
  @override
  Future<StorageConnection> connect(StorageSource source, StorageCredentials? credentials) => pending;
}
