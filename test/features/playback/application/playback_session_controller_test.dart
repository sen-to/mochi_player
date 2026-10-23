import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/playback/playback_target.dart';
import 'package:mochi_player/core/domain/playback/playback_target_resolver.dart';
import 'package:mochi_player/features/playback/application/playback_media_repository.dart';
import 'package:mochi_player/features/playback/application/playback_session_controller.dart';

MediaFile _file(int id, String path) =>
    MediaFile(id: id, path: path, fileName: path.split('/').last, parsedTitle: 'Show', addedAt: DateTime(2026));

class _FakePlaybackMediaRepository implements PlaybackMediaRepository {
  _FakePlaybackMediaRepository({this.failProgressWrites = false});

  final bool failProgressWrites;
  final progressWrites = <int>[];

  @override
  Future<MediaFile?> readMediaFile({required String sourceId, required String path}) async => _file(1, path);

  @override
  Future<void> updateProgress(MediaFile file, int position, {int? duration}) async {
    if (failProgressWrites) throw StateError('database unavailable');
    progressWrites.add(position);
  }
}

class _FakePlaybackTargetResolver implements PlaybackTargetResolver {
  _FakePlaybackTargetResolver(this._resolve);

  final Future<PlaybackTarget?> Function(MediaFile file) _resolve;

  @override
  Future<PlaybackTarget?> resolve(MediaFile file) => _resolve(file);
}

void main() {
  test('keeps old resources until the backend switches, then releases all on exit', () async {
    final first = _file(1, '/one.mkv');
    final second = _file(2, '/two.mkv');
    final oldResource = _Resource();
    final newResource = _Resource();
    final session = PlaybackSessionController(
      mediaRepository: _FakePlaybackMediaRepository(),
      initialItem: first,
      queueItems: [first, second],
      initialTarget: PlaybackTarget(url: 'http://127.0.0.1/old', resource: oldResource),
      resolver: _FakePlaybackTargetResolver(
        (_) async => PlaybackTarget(url: 'http://127.0.0.1/new', resource: newResource),
      ),
    );
    expect((await session.moveBy(1, positionMs: 0, durationMs: 0))?.isReady, isTrue);
    expect(oldResource.closed, isFalse);
    await session.releaseRetiredTargets();
    expect(oldResource.closed, isTrue);
    expect(newResource.closed, isFalse);
    await session.releaseTargets();
    expect(newResource.closed, isTrue);
  });

  test('late target resolution releases its resource after session shutdown', () async {
    final first = _file(1, '/one.mkv');
    final second = _file(2, '/two.mkv');
    final pending = Completer<PlaybackTarget?>();
    final resolving = Completer<void>();
    final resource = _Resource();
    final session = PlaybackSessionController(
      mediaRepository: _FakePlaybackMediaRepository(),
      initialItem: first,
      queueItems: [first, second],
      initialTarget: const PlaybackTarget(url: 'file:///one.mkv'),
      resolver: _FakePlaybackTargetResolver((_) {
        resolving.complete();
        return pending.future;
      }),
    );
    final move = session.moveBy(1, positionMs: 0, durationMs: 0);
    await resolving.future;
    await session.releaseTargets();
    pending.complete(PlaybackTarget(url: 'http://127.0.0.1/late', resource: resource));
    expect(await move, isNull);
    expect(resource.closed, isTrue);
    expect(session.currentItem, first);
  });

  test('a failed SMB resolution preserves the active target', () async {
    final first = _file(1, '/one.mkv');
    final second = _file(2, '/two.mkv');
    final resource = _Resource();
    final session = PlaybackSessionController(
      mediaRepository: _FakePlaybackMediaRepository(),
      initialItem: first,
      queueItems: [first, second],
      initialTarget: PlaybackTarget(url: 'http://127.0.0.1/old', resource: resource),
      resolver: _FakePlaybackTargetResolver((_) async => throw StateError('NAS unavailable')),
    );
    expect((await session.moveBy(1, positionMs: 0, durationMs: 0))?.isReady, isFalse);
    expect(session.currentItem, first);
    expect(resource.closed, isFalse);
    await session.releaseTargets();
  });

  test('exit during queue resolution cannot commit or start another media item', () async {
    final store = _FakePlaybackMediaRepository();
    final first = _file(1, '/one.mkv');
    final second = _file(2, '/two.mkv');
    final resolving = Completer<void>();
    final link = Completer<PlaybackTarget?>();
    final session = PlaybackSessionController(
      mediaRepository: store,
      initialItem: first,
      queueItems: [first, second],
      initialTarget: const PlaybackTarget(url: 'file:///one.mkv'),
      resolver: _FakePlaybackTargetResolver((_) {
        resolving.complete();
        return link.future;
      }),
    );
    final move = session.moveBy(1, positionMs: 10000, durationMs: 100000);
    await resolving.future;
    session.beginShutdown();
    await session.saveProgress(positionMs: 12000, durationMs: 100000, force: true);
    link.complete(const PlaybackTarget(url: 'file:///two.mkv'));
    expect(await move, isNull);
    expect(session.currentItem, first);
    expect(session.currentTarget.url, 'file:///one.mkv');
    expect(await session.moveBy(1, positionMs: 0, durationMs: 0), isNull);
    expect(store.progressWrites, [10000, 12000]);
  });

  test('saves current progress before resolving and committing a queue move', () async {
    final library = _FakePlaybackMediaRepository();
    final first = _file(1, '/media/one.mkv');
    final second = _file(2, '/media/two.mkv');
    final events = <String>[];
    final session = PlaybackSessionController(
      mediaRepository: library,
      initialItem: first,
      queueItems: [first, second],
      initialTarget: const PlaybackTarget(url: 'https://example.test/one'),
      resolver: _FakePlaybackTargetResolver((file) async {
        events.add('link:${file.path}');
        return const PlaybackTarget(url: 'https://example.test/two');
      }),
    );

    final move = await session.moveBy(1, positionMs: 4000, durationMs: 10000);

    expect(move?.isReady, isTrue);
    expect(session.currentItem, second);
    expect(session.currentTarget.url, 'https://example.test/two');
    expect(library.progressWrites, [4000]);
    expect(events, ['link:/media/two.mkv']);
  });

  test('keeps the current item when a target link cannot be resolved', () async {
    final library = _FakePlaybackMediaRepository();
    final first = _file(1, '/media/one.mkv');
    final second = _file(2, '/media/two.mkv');
    final session = PlaybackSessionController(
      mediaRepository: library,
      initialItem: first,
      queueItems: [first, second],
      initialTarget: const PlaybackTarget(url: 'https://example.test/one'),
      resolver: _FakePlaybackTargetResolver((_) async => null),
    );

    final move = await session.moveBy(1, positionMs: 4000, durationMs: 10000);

    expect(move?.isReady, isFalse);
    expect(session.currentItem, first);
    expect(session.currentTarget.url, 'https://example.test/one');
  });

  test('continues switching when progress persistence fails', () async {
    final library = _FakePlaybackMediaRepository(failProgressWrites: true);
    final first = _file(1, '/media/one.mkv');
    final second = _file(2, '/media/two.mkv');
    final session = PlaybackSessionController(
      mediaRepository: library,
      initialItem: first,
      queueItems: [first, second],
      initialTarget: const PlaybackTarget(url: 'https://example.test/one'),
      resolver: _FakePlaybackTargetResolver((_) async => const PlaybackTarget(url: 'https://example.test/two')),
    );

    final move = await session.moveBy(1, positionMs: 4000, durationMs: 10000);

    expect(move?.isReady, isTrue);
    expect(session.currentItem, second);
  });
}

class _Resource implements PlaybackTargetResource {
  bool closed = false;
  @override
  Future<void> close() async => closed = true;
}
