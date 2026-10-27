// 【播放后端契约】定义打开、控制、轨道、状态流和视频表面。
// 后端类型与任意 mpv 属性不进入调用方，会话负责引擎所有权。

import 'package:flutter/widgets.dart';
import 'package:mochi_player/core/domain/playback/playback_target.dart';
import 'package:mochi_player/features/playback/domain/playback_track.dart';

/// Flutter 播放边界；后端播放器、属性名称或轨道对象不能泄漏到调用方，视频表面与原生资源由后端封装。
abstract interface class PlaybackEngine {
  PlaybackState get state;

  PlaybackStreams get stream;

  Widget buildVideoSurface();

  /// 打开命令完成后结束等待；之后的解码错误通过状态流报告。
  Future<void> open(PlaybackTarget target, {Duration? start});

  /// 卸载媒体，完成后才说明可以释放对应目标资源。
  Future<void> stop();

  Future<void> pause();

  Future<void> playOrPause();

  Future<void> seek(Duration position);

  Future<void> setVolume(double volume);

  Future<void> setRate(double rate);

  Future<void> setAudioTrack(PlaybackAudioTrack track);

  Future<void> setSubtitleTrack(PlaybackSubtitleTrack track);

  Future<void> applyOptions(PlaybackOptions options);

  Future<void> setSubtitleStyleOverride(bool override);

  Future<double?> readCacheBytesPerSecond();

  /// 换片或关闭时，使待执行的选项修改失效。
  void cancelPendingCommands();

  Future<void> dispose();
}

class PlaybackOptions {
  const PlaybackOptions({
    required this.cacheMaxBytes,
    required this.readaheadSeconds,
    required this.hardwareAcceleration,
    required this.subtitleLanguagePriority,
  });

  final int cacheMaxBytes;
  final int readaheadSeconds;
  final bool hardwareAcceleration;
  final String subtitleLanguagePriority;
}

class PlaybackState {
  const PlaybackState({
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.buffer = Duration.zero,
    this.playing = false,
    this.volume = 100,
    this.rate = 1,
    this.tracks = const PlaybackTracks(),
  });

  final Duration position;
  final Duration duration;
  final Duration buffer;
  final bool playing;
  final double volume;
  final double rate;
  final PlaybackTracks tracks;
}

class PlaybackLog {
  const PlaybackLog({required this.prefix, required this.level, required this.text});

  final String prefix;
  final String level;
  final String text;
}

class PlaybackStreams {
  const PlaybackStreams({
    required this.position,
    required this.duration,
    required this.buffer,
    required this.playing,
    required this.volume,
    required this.rate,
    required this.error,
    required this.log,
    required this.tracks,
    required this.track,
    required this.buffering,
    required this.completed,
    required this.subtitle,
  });

  final Stream<Duration> position;
  final Stream<Duration> duration;
  final Stream<Duration> buffer;
  final Stream<bool> playing;
  final Stream<double> volume;
  final Stream<double> rate;
  final Stream<String> error;
  final Stream<PlaybackLog> log;
  final Stream<PlaybackTracks> tracks;
  final Stream<PlaybackSelectedTracks> track;
  final Stream<bool> buffering;
  final Stream<bool> completed;
  final Stream<List<String>> subtitle;
}
