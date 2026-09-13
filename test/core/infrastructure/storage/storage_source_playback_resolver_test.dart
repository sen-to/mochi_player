import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/infrastructure/storage/storage_source_playback_resolver.dart';
import 'package:mochi_player/core/infrastructure/storage/storage_source_repository.dart';

void main() {
  const source = StorageSource(
    id: 'home-nas',
    name: '家庭媒体库',
    type: StorageSourceType.webDav,
    endpoint: 'http://127.0.0.1:5244/dav',
  );

  test('resolves a source-owned file through its WebDAV endpoint', () async {
    final resolver = StorageSourcePlaybackResolver(
      repository: _FakeSourceRepository(
        source: source,
        credentials: const StorageCredentials(username: 'admin', password: 'secret'),
      ),
    );

    final target = await resolver.resolve(_file(sourceId: source.id));

    expect(target?.url, 'http://127.0.0.1:5244/dav/quark/example.mkv');
    expect(target?.httpHeaders, {'Authorization': 'Basic YWRtaW46c2VjcmV0'});
  });

  test('does not resolve a file without a configured source', () async {
    final resolver = StorageSourcePlaybackResolver(repository: _FakeSourceRepository());

    final target = await resolver.resolve(_file(sourceId: 'missing-source'));

    expect(target, isNull);
  });

  test('does not resolve a file from a disabled source', () async {
    final resolver = StorageSourcePlaybackResolver(
      repository: _FakeSourceRepository(source: source.copyWith(enabled: false)),
    );

    expect(await resolver.resolve(_file(sourceId: source.id)), isNull);
  });
}

MediaFile _file({required String sourceId}) => MediaFile(
  id: 1,
  sourceId: sourceId,
  path: '/quark/example.mkv',
  fileName: 'example.mkv',
  parsedTitle: 'Example',
  addedAt: DateTime(2026),
);

class _FakeSourceRepository implements StorageSourceRepository {
  _FakeSourceRepository({this.source, this.credentials});

  final StorageSource? source;
  final StorageCredentials? credentials;

  @override
  Future<bool> delete(String sourceId) async => false;

  @override
  Future<int?> deleteWithMedia(String sourceId) async => null;

  @override
  Future<List<StorageSource>> getAll() async => source == null ? const [] : [source!];

  @override
  Future<StorageSource?> getById(String sourceId) async => source?.id == sourceId ? source : null;

  @override
  Future<StorageCredentials?> readCredentials(String sourceId) async => source?.id == sourceId ? credentials : null;

  @override
  Future<void> save(StorageSource source, {StorageCredentials? credentials}) async {}
}
