import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/app_failure.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/playback/playback_target.dart';
import 'package:mochi_player/core/domain/playback/playback_target_resolver.dart';
import 'package:mochi_player/features/playback/application/playback_engine.dart';
import 'package:mochi_player/features/playback/application/playback_media_repository.dart';
import 'package:mochi_player/features/playback/application/playback_session_controller.dart';

import '../../../support/fake_playback_engine.dart';

const _options = PlaybackOptions(
  cacheMaxBytes: 1024,
  readaheadSeconds: 10,
  hardwareAcceleration: false,
  subtitleLanguagePriority: 'eng',
);

MediaFile _file(int id) => MediaFile(
  id: id,
  sourceId: 'source',
  path: '/$id.mkv',
  fileName: '$id.mkv',
  parsedTitle: 'Show',
  addedAt: DateTime(2026),
);

void main() {
  late _Fixture fixture;
  setUp(() => fixture = _Fixture());
  tearDown(() async {
    if (fixture.expectCloseFailure) {
      await expectLater(fixture.session.close(), throwsStateError);
    } else {
      await fixture.session.close();
    }
  });

  test('prepared target is owned before a page or engine exists, and closes once', () async {
    expect(await fixture.session.prepare(), isTrue);
    await Future.wait([fixture.session.close(), fixture.session.close()]);
    expect(fixture.resources[1]!.closes, 1);
    expect(fixture.engine.disposeCount, 0);
  });

  test('keeps the old target through the entire engine open and rejects overlapping moves', () async {
    await fixture.start();
    fixture.engine.openGate = Completer<void>();
    final move = fixture.session.moveBy(1, subtitleStyleOverride: false);
    await fixture.engine.openStarted.future;
    expect(fixture.resources[1]!.closes, 0);
    expect(fixture.resources[2]!.closes, 0);
    expect(await fixture.session.moveBy(1, subtitleStyleOverride: false), isNull);
    // A timer cannot write the old backend position against the new file.
    await fixture.session.saveProgress(positionMs: 4000, durationMs: 10000, force: true);
    expect(fixture.store.writes, isEmpty);
    fixture.engine.openGate!.complete();
    expect((await move)?.isReady, isTrue);
    expect(fixture.resources[1]!.closes, 1);
    expect(fixture.resources[2]!.closes, 0);
    expect(fixture.session.currentItem.path, '/2.mkv');
    await fixture.session.close();
    expect(fixture.events.indexOf('dispose'), lessThan(fixture.events.indexOf('release:2')));
  });

  test('resolver failure preserves the old item, resource and engine', () async {
    await fixture.start();
    fixture.resolve = (_) async => throw StateError('NAS unavailable');
    final result = await fixture.session.moveBy(1, subtitleStyleOverride: false);
    expect(result?.failure, AppFailure.playbackLink);
    expect(fixture.session.currentItem.path, '/1.mkv');
    expect(fixture.resources[1]!.closes, 0);
    expect(fixture.events.where((e) => e == 'open'), hasLength(1));
    expect(fixture.events, isNot(contains('stop')));
  });

  test('failed open stops the backend before releasing both targets, then allows another move', () async {
    await fixture.start();
    fixture.engine.failOpen = true;
    final result = await fixture.session.moveBy(1, subtitleStyleOverride: false);
    expect(result?.failure, AppFailure.playbackOpen);
    expect(fixture.events.indexOf('stop'), lessThan(fixture.events.indexOf('release:1')));
    expect(fixture.events.indexOf('stop'), lessThan(fixture.events.indexOf('release:2')));
    expect(fixture.resources[1]!.closes, 1);
    expect(fixture.resources[2]!.closes, 1);
    await fixture.session.saveProgress(positionMs: 9999, durationMs: 10000, force: true);
    expect(fixture.store.writes, isEmpty);
    fixture.engine.failOpen = false;
    expect((await fixture.session.moveBy(1, subtitleStyleOverride: false))?.isReady, isTrue);
    expect(fixture.session.currentItem.path, '/3.mkv');
  });

  test('option failure also stops and releases the attempted replacement', () async {
    await fixture.start();
    fixture.engine.failOptions = true;
    expect((await fixture.session.moveBy(1, subtitleStyleOverride: false))?.failure, AppFailure.playbackOpen);
    expect(fixture.resources[1]!.closes, 1);
    expect(fixture.resources[2]!.closes, 1);
    expect(fixture.events.indexOf('stop'), lessThan(fixture.events.indexOf('release:1')));
  });

  test('initial open failure stops before releasing its target', () async {
    await fixture.prepareEngine();
    fixture.engine.failOpen = true;
    await expectLater(fixture.session.openCurrent(subtitleStyleOverride: false), throwsStateError);
    expect(fixture.events.indexOf('stop'), lessThan(fixture.events.indexOf('release:1')));
    expect(fixture.resources[1]!.closes, 1);
  });

  test('stop failure disposes the engine before releasing either target', () async {
    await fixture.start();
    fixture.engine.failOpen = true;
    fixture.engine.failStop = true;
    expect((await fixture.session.moveBy(1, subtitleStyleOverride: false))?.failure, AppFailure.playbackOpen);
    expect(fixture.engine.disposeCount, 1);
    expect(fixture.events.indexOf('dispose'), lessThan(fixture.events.indexOf('release:1')));
    expect(fixture.events.indexOf('dispose'), lessThan(fixture.events.indexOf('release:2')));
    expect(await fixture.session.moveBy(1, subtitleStyleOverride: false), isNull);
  });

  test('shutdown during resolution closes existing resources and releases late results', () async {
    await fixture.start();
    final resolving = Completer<void>();
    final pending = Completer<PlaybackTarget?>();
    fixture.resolve = (_) {
      resolving.complete();
      return pending.future;
    };
    final move = fixture.session.moveBy(1, subtitleStyleOverride: false);
    await resolving.future;
    await fixture.session.close();
    final late = _Resource(2, fixture.events);
    pending.complete(PlaybackTarget(url: 'http://localhost/late', resource: late));
    expect(await move, isNull);
    expect(late.closes, 1);
    expect(fixture.resources[1]!.closes, 1);
    expect(fixture.session.currentItem.path, '/1.mkv');
    expect(fixture.events.where((e) => e == 'open'), hasLength(1));
  });

  test('shutdown during open waits for backend disposal before releasing targets', () async {
    await fixture.start();
    fixture.engine.openGate = Completer<void>();
    fixture.engine.disposeGate = Completer<void>();
    final move = fixture.session.moveBy(1, subtitleStyleOverride: false);
    await fixture.engine.openStarted.future;
    final closing = fixture.session.close();
    fixture.engine.openGate!.complete();
    await Future<void>.delayed(Duration.zero);
    expect(fixture.resources.values.every((r) => r.closes == 0), isTrue);
    fixture.engine.disposeGate!.complete();
    await closing;
    expect(await move, isNull);
    expect(fixture.resources.values.every((r) => r.closes == 1), isTrue);
    expect(fixture.engine.disposeCount, 1);
  });

  test('a resource close failure does not skip other owned resources', () async {
    await fixture.start();
    fixture.engine.openGate = Completer<void>();
    final move = fixture.session.moveBy(1, subtitleStyleOverride: false);
    await fixture.engine.openStarted.future;
    fixture.resources[1]!.fail = true;
    final closing = fixture.session.close();
    final closingCheck = expectLater(closing, throwsStateError);
    final moveCheck = expectLater(move, throwsStateError);
    fixture.engine.openGate!.complete();
    await Future.wait([closingCheck, moveCheck]);
    expect(fixture.resources.values.every((r) => r.closes == 1), isTrue);
    fixture.expectCloseFailure = true;
  });

  test('engine construction failure releases the prepared target without a mounted page', () async {
    await fixture.session.prepare();
    expect(() => fixture.session.attachEngine((_) => throw StateError('engine failed'), _options), throwsStateError);
    await fixture.session.close();
    expect(fixture.resources[1]!.closes, 1);
    expect(fixture.engine.disposeCount, 0);
  });

  test('prepareClose pauses and persists once, and prevents subsequent queue changes', () async {
    await fixture.start();
    fixture.engine.state = const PlaybackState(position: Duration(seconds: 7), duration: Duration(seconds: 20));
    await Future.wait([fixture.session.prepareClose(), fixture.session.prepareClose()]);
    expect(fixture.store.writes, [(path: '/1.mkv', position: 7000)]);
    expect(fixture.engine.events.where((e) => e == 'pause'), hasLength(1));
    expect(await fixture.session.moveBy(1, subtitleStyleOverride: false), isNull);
  });

  test('moving to an already-owned target never releases it while it is active', () async {
    await fixture.start();
    final target = fixture.session.currentTarget;
    fixture.resolve = (_) async => target;
    expect((await fixture.session.moveBy(0, subtitleStyleOverride: false))?.isReady, isTrue);
    expect(fixture.resources[1]!.closes, 0);
    await fixture.session.close();
    expect(fixture.resources[1]!.closes, 1);
  });

  test('reads the latest persisted progress before opening the next item', () async {
    await fixture.start();
    fixture.store.files['/2.mkv'] = _file(2).copyWith(position: 42000, duration: 100000);
    final result = await fixture.session.moveBy(1, subtitleStyleOverride: false);
    expect(result?.resumePosition, const Duration(seconds: 37));
    expect(fixture.engine.openedStart, const Duration(seconds: 37));
    expect(fixture.session.currentItem.position, 42000);
  });

  test('metadata read failure during open stops before releasing owned targets', () async {
    await fixture.start();
    fixture.store.failReads = true;
    expect((await fixture.session.moveBy(1, subtitleStyleOverride: false))?.failure, AppFailure.playbackOpen);
    expect(fixture.resources.values.every((r) => r.closes == 1), isTrue);
    expect(fixture.events.indexOf('stop'), lessThan(fixture.events.indexOf('release:2')));
  });

  test('saves progress for A before resolving B and tolerates persistence failure', () async {
    await fixture.start();
    fixture.engine.state = const PlaybackState(position: Duration(seconds: 4), duration: Duration(seconds: 10));
    fixture.store.failWrites = true;
    expect((await fixture.session.moveBy(1, subtitleStyleOverride: false))?.isReady, isTrue);
    expect(fixture.store.writes, [(path: '/1.mkv', position: 4000)]);
    expect(fixture.events.indexOf('save'), lessThan(fixture.events.indexOf('resolve:2')));
  });
}

class _Fixture {
  _Fixture() {
    engine = _Engine(events);
    store = _Repository(events);
    resolve = (file) async {
      events.add('resolve:${file.id}');
      final resource = _Resource(file.id, events);
      resources[file.id] = resource;
      return PlaybackTarget(url: 'http://localhost/${file.id}', resource: resource);
    };
    session = PlaybackSessionController(
      mediaRepository: store,
      initialItem: _file(1),
      queueItems: [_file(1), _file(2), _file(3)],
      resolver: _Resolver((file) => resolve(file)),
    );
  }
  bool expectCloseFailure = false;
  final events = <String>[];
  final resources = <int, _Resource>{};
  late final _Engine engine;
  late final _Repository store;
  late final PlaybackSessionController session;
  late Future<PlaybackTarget?> Function(MediaFile) resolve;

  Future<void> prepareEngine() async {
    expect(await session.prepare(), isTrue);
    session.attachEngine((_) => engine, _options);
  }

  Future<void> start() async {
    await prepareEngine();
    await session.openCurrent(subtitleStyleOverride: false);
  }
}

class _Engine extends FakePlaybackEngine {
  _Engine(this.trace);
  final List<String> trace;
  Completer<void>? openGate;
  Completer<void>? disposeGate;
  final openStarted = Completer<void>();
  bool failOpen = false;
  bool failStop = false;
  bool failOptions = false;

  @override
  Future<void> applyOptions(PlaybackOptions options) async {
    if (failOptions) throw StateError('options failed');
    await super.applyOptions(options);
  }

  @override
  Future<void> open(PlaybackTarget target, {Duration? start}) async {
    trace.add('open');
    if (openGate != null && !openStarted.isCompleted) openStarted.complete();
    await openGate?.future;
    if (failOpen) throw StateError('open failed');
    await super.open(target, start: start);
  }

  @override
  Future<void> stop() async {
    trace.add('stop');
    if (failStop) throw StateError('stop failed');
  }

  @override
  Future<void> dispose() async {
    await disposeGate?.future;
    trace.add('dispose');
    await super.dispose();
  }
}

class _Repository implements PlaybackMediaRepository {
  _Repository(this.trace);
  final List<String> trace;
  final writes = <({String path, int position})>[];
  bool failWrites = false;
  bool failReads = false;
  final files = <String, MediaFile>{};
  @override
  Future<MediaFile?> readMediaFile({required String sourceId, required String path}) async {
    if (failReads) throw StateError('read failed');
    return files[path];
  }

  @override
  Future<void> updateProgress(MediaFile file, int position, {int? duration}) async {
    trace.add('save');
    writes.add((path: file.path, position: position));
    if (failWrites) throw StateError('write failed');
  }
}

class _Resolver implements PlaybackTargetResolver {
  _Resolver(this.resolveFile);
  final Future<PlaybackTarget?> Function(MediaFile) resolveFile;
  @override
  Future<PlaybackTarget?> resolve(MediaFile file) => resolveFile(file);
}

class _Resource implements PlaybackTargetResource {
  _Resource(this.id, this.trace);
  final int id;
  final List<String> trace;
  int closes = 0;
  bool fail = false;
  @override
  Future<void> close() async {
    closes++;
    trace.add('release:$id');
    if (fail) throw StateError('close failed');
  }
}
