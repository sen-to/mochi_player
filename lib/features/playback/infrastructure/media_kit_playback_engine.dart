import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart' as kit;
import 'package:media_kit_video/media_kit_video.dart' as video;
import 'package:mochi_player/core/domain/playback/playback_target.dart';
import 'package:mochi_player/features/playback/application/playback_engine.dart';
import 'package:mochi_player/features/playback/domain/playback_track.dart';
import 'package:mochi_player/features/playback/infrastructure/libmpv_log_buffer.dart';

/// Current libmpv backend. Owns media_kit, rendering and all mpv property access.
class MediaKitPlaybackEngine implements PlaybackEngine {
  static void initialize() => kit.MediaKit.ensureInitialized();

  MediaKitPlaybackEngine(PlaybackOptions options) {
    _player = kit.Player(
      configuration: kit.PlayerConfiguration(
        title: 'Mochi Player',
        bufferSize: options.cacheMaxBytes,
        libass: true,
        logLevel: kit.MPVLogLevel.info,
      ),
    );
    _video = video.VideoController(
      _player,
      configuration: video.VideoControllerConfiguration(enableHardwareAcceleration: options.hardwareAcceleration),
    );
    final events = _player.stream;
    stream = PlaybackStreams(
      position: events.position,
      duration: events.duration,
      buffer: events.buffer,
      playing: events.playing,
      volume: events.volume,
      rate: events.rate,
      error: events.error.map(LibmpvLogBuffer.sanitize),
      log: events.log.map(
        (entry) => PlaybackLog(prefix: entry.prefix, level: entry.level, text: LibmpvLogBuffer.sanitize(entry.text)),
      ),
      tracks: events.tracks.map(_tracks),
      track: events.track.map(
        (track) => PlaybackSelectedTracks(audio: _audio(track.audio), subtitle: _subtitle(track.subtitle)),
      ),
      buffering: events.buffering,
      completed: events.completed,
      subtitle: events.subtitle,
    );
  }

  late final kit.Player _player;
  late final video.VideoController _video;
  @override
  late final PlaybackStreams stream;
  int _commandGeneration = 0;
  bool _disposed = false;
  Future<void>? _disposal;

  @override
  PlaybackState get state {
    final current = _player.state;
    return PlaybackState(
      position: current.position,
      duration: current.duration,
      buffer: current.buffer,
      playing: current.playing,
      volume: current.volume,
      rate: current.rate,
      tracks: _tracks(current.tracks),
    );
  }

  @override
  Widget buildVideoSurface() => video.Video(
    controller: _video,
    controls: (_) => const SizedBox.shrink(),
    subtitleViewConfiguration: const video.SubtitleViewConfiguration(
      style: TextStyle(fontSize: 0, color: Colors.transparent),
    ),
  );

  @override
  Future<void> open(PlaybackTarget target, {Duration? start}) => _player.open(
    kit.Media(target.url, httpHeaders: {'User-Agent': 'MochiPlayer/1.0.0', ...target.httpHeaders}, start: start),
    play: true,
  );
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> playOrPause() => _player.playOrPause();
  @override
  Future<void> seek(Duration position) => _player.seek(position);
  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);
  @override
  Future<void> setRate(double rate) => _player.setRate(rate);
  @override
  Future<void> setAudioTrack(PlaybackAudioTrack track) => _player.setAudioTrack(
    kit.AudioTrack(track.id, track.title, track.language, uri: track.origin == PlaybackTrackOrigin.externalFile),
  );
  @override
  Future<void> setSubtitleTrack(PlaybackSubtitleTrack track) => _player.setSubtitleTrack(
    kit.SubtitleTrack(
      track.id,
      track.title,
      track.language,
      uri: track.origin == PlaybackTrackOrigin.externalFile,
      data: track.origin == PlaybackTrackOrigin.externalData,
    ),
  );

  @override
  Future<void> applyOptions(PlaybackOptions options) => _applyProperties({
    'cache': 'yes',
    'cache-pause': 'yes',
    'cache-pause-wait': '3',
    'cache-secs': options.readaheadSeconds.toString(),
    'demuxer-readahead-secs': options.readaheadSeconds.toString(),
    'demuxer-max-bytes': options.cacheMaxBytes.toString(),
    'demuxer-max-back-bytes': (options.cacheMaxBytes ~/ 4).toString(),
    'hwdec': options.hardwareAcceleration ? 'auto' : 'no',
    'slang': options.subtitleLanguagePriority,
    'vo-profile': 'high-quality',
  });

  @override
  Future<void> setSubtitleStyleOverride(bool override) {
    final visible = override ? 'no' : 'yes';
    return _applyProperties({'sub-ass': visible, 'sub-visibility': visible, 'secondary-sub-visibility': visible});
  }

  Future<void> _applyProperties(Map<String, String> properties) async {
    final native = _player.platform;
    if (native is! kit.NativePlayer) return;
    final generation = _commandGeneration;
    for (final entry in properties.entries) {
      if (_disposed || generation != _commandGeneration) return;
      try {
        await native.setProperty(entry.key, entry.value);
      } catch (error) {
        debugPrint('应用播放设置失败 ${entry.key}: ${LibmpvLogBuffer.sanitize(error.toString())}');
      }
    }
  }

  @override
  Future<double?> readCacheBytesPerSecond() async {
    if (_disposed) return null;
    final native = _player.platform;
    if (native is! kit.NativePlayer) return null;
    try {
      final speed = double.tryParse(await native.getProperty('cache-speed'));
      return speed != null && speed.isFinite && speed > 0 ? speed : null;
    } catch (_) {
      return null; // Not available before opening or for some local files.
    }
  }

  @override
  void cancelPendingCommands() => _commandGeneration++;
  @override
  Future<void> dispose() {
    if (_disposal != null) return _disposal!;
    _disposed = true;
    cancelPendingCommands();
    return _disposal = _player.dispose();
  }

  static PlaybackTrackOrigin _origin(String id, bool uri, [bool data = false]) {
    if (uri) return PlaybackTrackOrigin.externalFile;
    if (data) return PlaybackTrackOrigin.externalData;
    if (id == 'auto') return PlaybackTrackOrigin.automatic;
    if (id == 'no') return PlaybackTrackOrigin.disabled;
    return PlaybackTrackOrigin.embedded;
  }

  static PlaybackAudioTrack _audio(kit.AudioTrack track) => PlaybackAudioTrack(
    track.id,
    track.title,
    track.language,
    origin: _origin(track.id, track.uri),
    isDefault: track.isDefault,
    codec: track.codec,
    channels: track.channels,
  );
  static PlaybackSubtitleTrack _subtitle(kit.SubtitleTrack track) => PlaybackSubtitleTrack(
    track.id,
    track.title,
    track.language,
    origin: _origin(track.id, track.uri, track.data),
    isDefault: track.isDefault,
  );
  static PlaybackTracks _tracks(kit.Tracks tracks) => PlaybackTracks(
    audio: List.unmodifiable(tracks.audio.map(_audio)),
    subtitle: List.unmodifiable(tracks.subtitle.map(_subtitle)),
  );
}
