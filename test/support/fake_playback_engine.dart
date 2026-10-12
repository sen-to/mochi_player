import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mochi_player/core/domain/playback/playback_target.dart';
import 'package:mochi_player/features/playback/application/playback_engine.dart';
import 'package:mochi_player/features/playback/domain/playback_track.dart';

class FakePlaybackEngine implements PlaybackEngine {
  final events = <String>[];
  final tracks = StreamController<PlaybackTracks>.broadcast(sync: true);
  final selected = StreamController<PlaybackSelectedTracks>.broadcast(sync: true);
  final subtitles = StreamController<List<String>>.broadcast(sync: true);
  final playing = StreamController<bool>.broadcast(sync: true);
  final errors = StreamController<String>.broadcast(sync: true);
  final positions = StreamController<Duration>.broadcast(sync: true);
  final volumes = StreamController<double>.broadcast(sync: true);
  final rates = StreamController<double>.broadcast(sync: true);
  PlaybackTarget? openedTarget;
  Duration? openedStart;
  PlaybackOptions? appliedOptions;
  PlaybackSubtitleTrack? lastSubtitle;
  PlaybackAudioTrack? lastAudio;
  Duration? sought;
  bool? overrideStyle;
  int disposeCount = 0;
  int toggles = 0;
  int cacheReads = 0;
  Completer<void>? pauseGate;
  @override
  PlaybackState state = const PlaybackState();
  @override
  late final stream = PlaybackStreams(
    position: positions.stream,
    duration: const Stream.empty(),
    buffer: const Stream.empty(),
    playing: playing.stream,
    volume: volumes.stream,
    rate: rates.stream,
    error: errors.stream,
    log: const Stream.empty(),
    tracks: tracks.stream,
    track: selected.stream,
    buffering: const Stream.empty(),
    completed: const Stream.empty(),
    subtitle: subtitles.stream,
  );

  @override
  Widget buildVideoSurface() => const SizedBox();

  @override
  Future<void> open(PlaybackTarget target, {Duration? start}) async {
    events.add('open');
    openedTarget = target;
    openedStart = start;
  }

  @override
  Future<void> applyOptions(PlaybackOptions options) async {
    events.add('options');
    appliedOptions = options;
  }

  @override
  Future<void> setSubtitleStyleOverride(bool override) async {
    events.add('style');
    overrideStyle = override;
  }

  @override
  Future<void> pause() async {
    events.add('pause');
    await pauseGate?.future;
  }

  @override
  Future<void> playOrPause() async {
    toggles++;
  }

  @override
  Future<void> seek(Duration position) async {
    sought = position;
  }

  @override
  Future<void> setVolume(double volume) async {
    volumes.add(volume);
  }

  @override
  Future<void> setRate(double rate) async {
    rates.add(rate);
  }

  @override
  Future<void> setAudioTrack(PlaybackAudioTrack track) async {
    lastAudio = track;
  }

  @override
  Future<void> setSubtitleTrack(PlaybackSubtitleTrack track) async {
    lastSubtitle = track;
  }

  @override
  Future<double?> readCacheBytesPerSecond() async {
    cacheReads++;
    return 2048;
  }

  @override
  void cancelPendingCommands() {
    events.add('cancel');
  }

  @override
  Future<void> dispose() async {
    disposeCount++;
    events.add('dispose');
    await Future.wait([
      tracks.close(),
      selected.close(),
      subtitles.close(),
      playing.close(),
      errors.close(),
      positions.close(),
      volumes.close(),
      rates.close(),
    ]);
  }
}
