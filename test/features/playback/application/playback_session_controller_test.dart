import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/playback/playback_target.dart';
import 'package:mochi_player/core/domain/playback/playback_target_resolver.dart';
import 'package:mochi_player/features/playback/application/playback_media_store.dart';
import 'package:mochi_player/features/playback/application/playback_session_controller.dart';

MediaFile _file(int id, String path) =>
    MediaFile(id: id, path: path, fileName: path.split('/').last, parsedTitle: 'Show', addedAt: DateTime(2026));

class _FakePlaybackMediaStore implements PlaybackMediaStore {
  _FakePlaybackMediaStore({this.failProgressWrites = false});

  final bool failProgressWrites;
  final progressWrites = <int>[];

  @override
  Iterable<PlaybackMediaKey> get changedMedia => const [];

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
  test('exit during queue resolution cannot commit or start another media item', () async {
    final store = _FakePlaybackMediaStore();
    final first = _file(1, '/one.mkv');
    final second = _file(2, '/two.mkv');
    final resolving = Completer<void>();
    final link = Completer<PlaybackTarget?>();
    final session = PlaybackSessionController(
      mediaStore: store,
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
    final library = _FakePlaybackMediaStore();
    final first = _file(1, '/media/one.mkv');
    final second = _file(2, '/media/two.mkv');
    final events = <String>[];
    final session = PlaybackSessionController(
      mediaStore: library,
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
    final library = _FakePlaybackMediaStore();
    final first = _file(1, '/media/one.mkv');
    final second = _file(2, '/media/two.mkv');
    final session = PlaybackSessionController(
      mediaStore: library,
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
    final library = _FakePlaybackMediaStore(failProgressWrites: true);
    final first = _file(1, '/media/one.mkv');
    final second = _file(2, '/media/two.mkv');
    final session = PlaybackSessionController(
      mediaStore: library,
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
