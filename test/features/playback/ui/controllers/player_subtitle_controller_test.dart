// 【行为测试】验证维护选轨、语言优先级、外挂字幕身份与样式覆盖。
// 测试对象的职责边界：只借用引擎；换片使旧操作失效，关闭时取消自己的订阅。

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/features/playback/domain/playback_track.dart';
import 'package:mochi_player/features/playback/ui/controllers/player_subtitle_controller.dart';

import '../../../../support/fake_playback_engine.dart';

void main() {
  late _SubtitleEngine engine;
  late PlayerSubtitleController controller;
  late bool canControl;
  late int activities;

  setUp(() {
    engine = _SubtitleEngine();
    canControl = true;
    activities = 0;
    controller = PlayerSubtitleController(
      engine: engine,
      languagePriority: 'zh,eng',
      canControlPlayback: () => canControl,
      onPlaybackActivity: () => activities++,
    );
  });

  tearDown(() async {
    await controller.shutdown();
    controller.dispose();
    await engine.dispose();
  });

  test('language preference selects once and a manual choice survives track refresh', () async {
    const english = PlaybackSubtitleTrack('1', 'English', 'eng');
    const chinese = PlaybackSubtitleTrack('2', '简体中文', null);
    engine.tracks.add(const PlaybackTracks(subtitle: [english, chinese, chinese]));
    await Future<void>.delayed(Duration.zero);
    expect(engine.lastSubtitle, chinese);
    expect(controller.subtitleTracks, [const PlaybackSubtitleTrack.disabled(), english, chinese]);

    await controller.setSubtitleTrack(const PlaybackSubtitleTrack.disabled());
    engine.tracks.add(const PlaybackTracks(subtitle: [english, chinese]));
    expect(controller.selectedSubtitleTrack.isDisabled, true);
    expect(engine.lastSubtitle!.isDisabled, true);
  });

  test('selection events before the track list do not require a populated menu', () {
    const selected = PlaybackSubtitleTrack('1', 'English', 'eng');
    engine.selected.add(const PlaybackSelectedTracks(subtitle: selected));
    expect(controller.selectedSubtitleTrack, selected);
  });

  test('reset clears per-media subtitles and reloads the same path for the new media', () async {
    await controller.loadExternalSubtitle('/movie.zh.srt');
    controller.setSubtitleStyleOverride(true);
    engine.subtitles.add(['old subtitle']);
    controller.resetForMedia();
    expect(controller.subtitle, isEmpty);
    expect(controller.subtitleTracks, isEmpty);
    expect(controller.selectedSubtitleTrack.isAutomatic, true);
    expect(controller.overrideEmbeddedSubtitleStyle, true);
    await controller.loadExternalSubtitle('/movie.zh.srt');
    expect(engine.externalLoads, 2);
  });

  test('late external load cannot update the next media or apply its subtitle style', () async {
    engine.subtitleGate = Completer<void>();
    final loading = controller.loadExternalSubtitle('/old.zh.srt');
    controller.resetForMedia();
    engine.subtitleGate!.complete();
    expect(await loading, false);
    expect(controller.subtitleTracks, isEmpty);
    expect(controller.selectedSubtitleTrack.isAutomatic, true);
    expect(engine.overrideStyle, isNull);
    expect(activities, 0);
  });

  test('late failed load cannot remove a new load of the same path after a reset', () async {
    final oldGate = Completer<void>();
    engine.subtitleGate = oldGate;
    final oldLoad = controller.loadExternalSubtitle('/same.zh.srt');
    controller.resetForMedia();
    engine.subtitleGate = null;
    expect(await controller.loadExternalSubtitle('/same.zh.srt'), true);
    oldGate.completeError(StateError('old media closed'));
    expect(await oldLoad, false);
    const loaded = PlaybackSubtitleTrack('9', 'same.zh', null);
    engine.tracks.add(const PlaybackTracks(subtitle: [loaded]));
    expect(controller.selectedSubtitleTrack, loaded);
    await controller.loadExternalSubtitle('/same.zh.srt');
    expect(engine.externalLoads, 2);
    expect(engine.lastSubtitle, loaded);
  });

  test('shutdown cancels subscriptions and blocks late commands without disposing the borrowed engine', () async {
    var notifications = 0;
    controller.addListener(() => notifications++);
    engine.subtitleGate = Completer<void>();
    final loading = controller.loadExternalSubtitle('/old.srt');
    await controller.shutdown();
    engine.subtitles.add(['late subtitle']);
    engine.subtitleGate!.complete();
    expect(await loading, false);
    expect(await controller.loadExternalSubtitle('/new.srt'), false);
    expect(notifications, 0);
    expect(engine.disposeCount, 0);
    expect(activities, 0);
  });

  test('the owner closing blocks state updates before subscriptions are detached', () async {
    canControl = false;
    engine.subtitles.add(['ignored']);
    expect(controller.subtitle, isEmpty);
    expect(await controller.loadExternalSubtitle('/new.srt'), false);
    expect(engine.externalLoads, 0);
  });
}

class _SubtitleEngine extends FakePlaybackEngine {
  Completer<void>? subtitleGate;
  int externalLoads = 0;

  @override
  Future<void> setSubtitleTrack(PlaybackSubtitleTrack track) async {
    if (track.origin == PlaybackTrackOrigin.externalFile) externalLoads++;
    await subtitleGate?.future;
    await super.setSubtitleTrack(track);
  }
}
