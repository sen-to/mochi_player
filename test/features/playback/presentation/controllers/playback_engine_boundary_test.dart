import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/playback/playback_target.dart';
import 'package:mochi_player/core/domain/playback/playback_target_resolver.dart';
import 'package:mochi_player/features/playback/application/playback_engine.dart';
import 'package:mochi_player/features/playback/application/playback_media_repository.dart';
import 'package:mochi_player/features/playback/application/playback_session_controller.dart';
import 'package:mochi_player/features/playback/domain/playback_track.dart';
import 'package:mochi_player/features/playback/presentation/controllers/player_playback_controller.dart';
import 'package:mochi_player/features/playback/presentation/widgets/player_controls.dart';
import 'package:mochi_player/features/settings/domain/app_settings.dart';
import 'package:mochi_player/l10n/l10n.dart';

import '../../../../support/fake_playback_engine.dart';

class _Repository implements PlaybackMediaRepository {
  _Repository(this.item, this.events);

  final MediaFile item;
  final List<String> events;
  int? savedPosition;

  @override
  Future<MediaFile?> readMediaFile({required String sourceId, required String path}) async => item;

  @override
  Future<void> updateProgress(MediaFile file, int position, {int? duration}) async {
    events.add('save');
    savedPosition = position;
  }
}

void main() {
  late FakePlaybackEngine engine;
  late _Repository store;
  late PlayerPlaybackController controller;
  const target = PlaybackTarget(url: 'https://example.com/movie.mkv', httpHeaders: {'Authorization': 'test'});
  setUp(() async {
    engine = FakePlaybackEngine();
    final item = MediaFile(
      id: 1,
      sourceId: 'test',
      path: '/movie.mkv',
      fileName: 'movie.mkv',
      parsedTitle: 'Movie',
      addedAt: DateTime(2026),
    );
    store = _Repository(item, engine.events);
    final session = PlaybackSessionController(
      mediaRepository: store,
      initialItem: item,
      queueItems: [item],
      resolver: _Resolver(target),
    );
    await session.prepare();
    controller = PlayerPlaybackController(
      engineFactory: (_) => engine,
      session: session,
      settings: const AppSettings(
        playbackCacheSizeMb: 128,
        playbackReadaheadSeconds: 30,
        enableHardwareAcceleration: false,
        subtitleLanguagePriority: 'ja,eng',
      ),
    );
  });
  tearDown(() async {
    await controller.shutdown();
    controller.dispose();
  });

  test('opens with domain target and typed options without a native player', () async {
    await controller.initialize();
    expect(engine.openedTarget, same(target));
    expect(engine.openedTarget!.httpHeaders['Authorization'], 'test');
    expect(engine.appliedOptions!.cacheMaxBytes, 128 * 1024 * 1024);
    expect(engine.appliedOptions!.readaheadSeconds, 30);
    expect(engine.appliedOptions!.hardwareAcceleration, false);
    expect(engine.appliedOptions!.subtitleLanguagePriority, 'ja,eng');
    expect(engine.events.indexOf('options'), lessThan(engine.events.indexOf('open')));
  });

  test('a failed initial open presents an error and releases its target before window shutdown', () async {
    final resource = _TargetResource();
    final failedEngine = _FailingOpenEngine();
    final session = PlaybackSessionController(
      mediaRepository: store,
      initialItem: store.item,
      queueItems: [store.item],
      resolver: _Resolver(PlaybackTarget(url: 'http://127.0.0.1/video?token=old', resource: resource)),
    );
    await session.prepare();
    final failedController = PlayerPlaybackController(
      engineFactory: (_) => failedEngine,
      session: session,
      settings: const AppSettings(),
    );
    try {
      await failedController.initialize();
      expect(failedController.playerError, isNotNull);
      expect(resource.closeCalls, 1);
    } finally {
      await failedController.shutdown();
      failedController.dispose();
    }
  });

  test('failed stop closes the session and blocks further playback interaction', () async {
    final failedEngine = _FailingStopEngine();
    final session = PlaybackSessionController(
      mediaRepository: store,
      initialItem: store.item,
      queueItems: [store.item],
      resolver: _Resolver(target),
    );
    await session.prepare();
    final failedController = PlayerPlaybackController(
      engineFactory: (_) => failedEngine,
      session: session,
      settings: const AppSettings(),
    );
    try {
      await failedController.initialize();
      expect(failedController.playerError, isNotNull);
      expect(failedController.canControlPlayback, isFalse);
      expect(failedEngine.disposeCount, 1);
      expect(await failedController.setAudioTrack(const PlaybackAudioTrack('1', null, null)), isFalse);
      await failedController.playQueueOffset(0);
      expect(failedEngine.disposeCount, 1);
    } finally {
      await failedController.shutdown();
      failedController.dispose();
    }
  });

  test('a post-open subtitle command failure is presented instead of escaping a queue action', () async {
    final failingEngine = _FinalStyleFailingEngine();
    final session = PlaybackSessionController(
      mediaRepository: store,
      initialItem: store.item,
      queueItems: [store.item],
      resolver: _Resolver(target),
    );
    await session.prepare();
    final player = PlayerPlaybackController(
      engineFactory: (_) => failingEngine,
      session: session,
      settings: const AppSettings(),
    );
    try {
      await player.initialize();
      expect(player.playerError, isNull);
      await player.playQueueOffset(0);
      expect(player.playerError, isNotNull);
      expect(player.canControlPlayback, isTrue);
    } finally {
      await player.shutdown();
      player.dispose();
    }
  });

  test('domain track events retain metadata, selection and external subtitle identity', () async {
    const audio = PlaybackAudioTrack('1', 'Japanese', 'ja', codec: 'aac', channels: '5.1', isDefault: true);
    const subtitle = PlaybackSubtitleTrack('2', 'Japanese', 'ja');
    engine.state = const PlaybackState(
      tracks: PlaybackTracks(audio: [audio], subtitle: [subtitle]),
    );
    engine.tracks.add(engine.state.tracks);
    await Future<void>.delayed(Duration.zero);
    expect(controller.audioTracks.single.channels, '5.1');
    expect(controller.selectedSubtitleTrack, subtitle);
    await controller.setAudioTrack(audio);
    expect(engine.lastAudio, audio);
    expect(await controller.loadExternalSubtitle('/movie.zh.srt'), true);
    expect(engine.lastSubtitle!.origin, PlaybackTrackOrigin.externalFile);
    const loaded = PlaybackSubtitleTrack('3', 'movie.zh', null);
    engine.tracks.add(const PlaybackTracks(audio: [audio], subtitle: [subtitle, loaded]));
    expect(controller.selectedSubtitleTrack, loaded);
    await controller.loadExternalSubtitle('/movie.zh.srt');
    expect(engine.lastSubtitle, loaded);
    await controller.setSubtitleTrack(const PlaybackSubtitleTrack.disabled());
    expect(engine.lastSubtitle!.isDisabled, true);
    controller.setSubtitleStyleOverride(true);
    await Future<void>.delayed(Duration.zero);
    expect(engine.overrideStyle, true);
  });

  test('shutdown pauses before final snapshot and disposes the injected engine once', () async {
    await controller.initialize();
    engine.state = const PlaybackState(position: Duration(seconds: 42), duration: Duration(seconds: 100));
    engine.pauseGate = Completer<void>();
    final preparing = controller.prepareClose();
    await Future<void>.delayed(Duration.zero);
    expect(store.savedPosition, isNull);
    engine.pauseGate!.complete();
    await preparing;
    expect(store.savedPosition, 42000);
    expect(engine.events.indexOf('pause'), lessThan(engine.events.indexOf('save')));
    expect(await controller.setAudioTrack(const PlaybackAudioTrack('1', null, null)), false);
    await Future.wait([controller.shutdown(), controller.shutdown()]);
    expect(engine.disposeCount, 1);
    expect(engine.events.indexOf('save'), lessThan(engine.events.indexOf('dispose')));
  });

  testWidgets('controls consume engine state and send play and seek through the boundary', (tester) async {
    engine.state = const PlaybackState(position: Duration(seconds: 30), duration: Duration(minutes: 2));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PlayerControls(engine: engine, isVisible: true, isFullScreen: false, onToggleFullScreen: () {}),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
    expect(engine.toggles, 1);
    await tester.tap(find.byIcon(Icons.forward_10_rounded));
    await tester.pump();
    expect(engine.sought, const Duration(seconds: 40));
    expect(engine.cacheReads, greaterThan(0));
    engine.playing.add(true);
    await tester.pump();
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}

class _Resolver implements PlaybackTargetResolver {
  _Resolver(this.target);
  final PlaybackTarget target;
  @override
  Future<PlaybackTarget?> resolve(MediaFile file) async => target;
}

class _FailingOpenEngine extends FakePlaybackEngine {
  @override
  Future<void> open(PlaybackTarget target, {Duration? start}) async => throw StateError('Unsupported media');
}

class _TargetResource implements PlaybackTargetResource {
  int closeCalls = 0;
  @override
  Future<void> close() async => closeCalls++;
}

class _FailingStopEngine extends _FailingOpenEngine {
  @override
  Future<void> stop() async => throw StateError('stop failed');
}

class _FinalStyleFailingEngine extends FakePlaybackEngine {
  int styleCalls = 0;
  @override
  Future<void> setSubtitleStyleOverride(bool override) async {
    if (++styleCalls == 4) throw StateError('subtitle update failed');
    await super.setSubtitleStyleOverride(override);
  }
}
