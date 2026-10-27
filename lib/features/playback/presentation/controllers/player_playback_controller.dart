import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mochi_player/features/playback/presentation/controllers/player_subtitle_controller.dart';
import 'package:mochi_player/core/domain/app_failure.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/formatters/media_format.dart';
import 'package:mochi_player/features/playback/application/playback_engine.dart';
import 'package:mochi_player/features/playback/application/playback_session_controller.dart';
import 'package:mochi_player/features/playback/domain/playback_track.dart';
import 'package:mochi_player/features/playback/application/playback_log_buffer.dart';
import 'package:mochi_player/features/settings/domain/app_settings.dart';

/// Presents playback state and translates UI actions into session commands.
/// Window modes and widget-only interaction state remain outside.
class PlayerPlaybackController extends ChangeNotifier {
  static const Duration _progressSaveInterval = Duration(seconds: 10);
  static const Duration localBufferingIndicatorDelay = Duration(milliseconds: 350);

  PlayerPlaybackController({
    required PlaybackSessionController session,
    required AppSettings settings,
    required PlaybackEngine Function(PlaybackOptions) engineFactory,
    this.onPlaybackActivity,
  }) : _session = session,
       engine = session.attachEngine(engineFactory, optionsFor(settings)) {
    subtitles = PlayerSubtitleController(
      engine: engine,
      languagePriority: settings.normalizedSubtitleLanguagePriority,
      canControlPlayback: () => canControlPlayback,
      onPlaybackActivity: onPlaybackActivity,
    )..addListener(_relaySubtitleState);
    _bindPlayerStreams();
  }

  final PlaybackSessionController _session;
  final VoidCallback? onPlaybackActivity;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final PlaybackLogBuffer _playbackLogs = PlaybackLogBuffer();

  final PlaybackEngine engine;
  late final PlayerSubtitleController subtitles;

  void _relaySubtitleState() {
    if (!_isDisposed && !_isClosing) notifyListeners();
  }

  Timer? _progressSaveTimer;
  Timer? _resumeNoticeTimer;
  bool _isDisposed = false;
  bool _isClosing = false;
  Future<void>? _shutdown;
  bool _hasRestoredPosition = false;
  bool _hasFlushedProgress = false;
  bool _isBuffering = false;
  bool _isBufferingIndicatorVisible = false;
  Timer? _bufferingIndicatorTimer;
  bool _showResumeNotice = false;
  int _mediaOpenGeneration = 0;
  double _lastVolumeBeforeMute = 100;
  AppFailure? _playerError;
  String? _resumePositionLabel;
  List<PlaybackAudioTrack> _audioTracks = const [];
  PlaybackAudioTrack _selectedAudioTrack = const PlaybackAudioTrack.automatic();

  MediaFile get currentItem => _session.currentItem;

  bool get canControlPlayback => !_isDisposed && !_isClosing && !_session.isClosed;

  bool get hasPrevious => _session.hasPrevious;

  bool get hasNext => _session.hasNext;

  bool get isBuffering => _isBufferingIndicatorVisible;

  @visibleForTesting
  static Duration bufferingIndicatorDelayFor(String mediaUrl) {
    final scheme = Uri.tryParse(mediaUrl)?.scheme.toLowerCase();
    return scheme == 'http' || scheme == 'https' ? Duration.zero : localBufferingIndicatorDelay;
  }

  bool get showResumeNotice => _showResumeNotice;

  AppFailure? get playerError => _playerError;

  String? get resumePositionLabel => _resumePositionLabel;

  List<PlaybackAudioTrack> get audioTracks => _audioTracks;

  PlaybackAudioTrack get selectedAudioTrack => _selectedAudioTrack;

  Future<void> initialize() => _openMedia(_nextMediaOpenGeneration());

  void clearError() {
    if (_playerError == null || _isDisposed) return;
    _playerError = null;
    notifyListeners();
  }

  Future<void> playQueueOffset(int offset) async {
    if (!canControlPlayback || _session.isSwitching) return;

    final generation = _nextMediaOpenGeneration();
    _setBuffering(true);
    _playerError = null;
    _showResumeNotice = false;
    notifyListeners();

    final PlaybackQueueMoveResult? move;
    try {
      move = await _session.moveBy(
        offset,
        subtitleStyleOverride: subtitles.overrideEmbeddedSubtitleStyle,
        onMediaChanged: () {
          _resumeNoticeTimer?.cancel();
          _progressSaveTimer?.cancel();
          _resetMediaState();
          notifyListeners();
        },
      );
    } catch (error) {
      debugPrint('切换媒体失败: ${PlaybackLogBuffer.sanitize(error.toString())}');
      if (_canUsePlayer(generation)) {
        _setBuffering(false);
        _playerError = AppFailure.playbackOpen;
        notifyListeners();
      }
      return;
    }
    if (!_canUsePlayer(generation)) return;
    if (move == null || !move.isReady) {
      _setBuffering(false);
      _playerError = move?.failure;
      notifyListeners();
      return;
    }
    await _finishOpen(move.resumePosition, generation);
  }

  Future<bool> setAudioTrack(PlaybackAudioTrack track) async {
    if (!canControlPlayback) return false;
    _selectedAudioTrack = track;
    notifyListeners();
    try {
      await engine.setAudioTrack(track);
    } catch (error) {
      debugPrint('切换音轨失败: $error');
      return false;
    }
    if (!canControlPlayback) return false;
    onPlaybackActivity?.call();
    return true;
  }

  void cycleAudioTrack() {
    if (!canControlPlayback || _audioTracks.isEmpty) return;
    final currentIndex = _audioTracks.indexOf(_selectedAudioTrack);
    final nextIndex = currentIndex < 0 ? 0 : (currentIndex + 1) % _audioTracks.length;
    unawaited(setAudioTrack(_audioTracks[nextIndex]));
  }

  void adjustVolume(double delta) {
    if (!canControlPlayback) return;
    final nextVolume = (engine.state.volume + delta).clamp(0.0, 100.0);
    engine.setVolume(nextVolume);
    if (nextVolume > 0) _lastVolumeBeforeMute = nextVolume;
    onPlaybackActivity?.call();
  }

  void toggleMute() {
    if (!canControlPlayback) return;
    final currentVolume = engine.state.volume;
    if (currentVolume > 0) {
      _lastVolumeBeforeMute = currentVolume;
      engine.setVolume(0);
    } else {
      engine.setVolume(_lastVolumeBeforeMute <= 0 ? 100 : _lastVolumeBeforeMute);
    }
    onPlaybackActivity?.call();
  }

  void _bindPlayerStreams() {
    _subscriptions.addAll([
      engine.stream.error.listen((error) {
        if (_isDisposed || _isClosing) return;
        debugPrint('播放器错误: ${PlaybackLogBuffer.sanitize(error)}');
        _dumpLibmpvLogs();
        _playerError = AppFailure.playbackOpen;
        notifyListeners();
      }),
      engine.stream.log.listen((log) {
        if (!_isDisposed) _playbackLogs.add(log);
      }),
      engine.stream.tracks.listen((tracks) {
        if (_isDisposed || _isClosing) return;
        _audioTracks = _normalizeAudioTracks(tracks.audio);
        _selectedAudioTrack = _resolveDisplayedAudioTrack(_selectedAudioTrack, _audioTracks);
        notifyListeners();
      }),
      engine.stream.track.listen((track) {
        if (_isDisposed || _isClosing) return;
        if (!track.audio.isAutomatic) {
          _selectedAudioTrack = track.audio;
        }
        notifyListeners();
      }),
      engine.stream.buffering.listen((buffering) {
        if (_isDisposed || _isClosing) return;
        _setBuffering(buffering);
        notifyListeners();
      }),
      engine.stream.playing.listen((_) {
        if (!_isDisposed) onPlaybackActivity?.call();
      }),
      engine.stream.completed.listen((completed) {
        if (!_isDisposed && completed) unawaited(_handlePlaybackCompleted());
      }),
    ]);
  }

  Future<void> _openMedia(int generation) async {
    try {
      final start = await _session.openCurrent(subtitleStyleOverride: subtitles.overrideEmbeddedSubtitleStyle);
      if (_canUsePlayer(generation)) await _finishOpen(start, generation);
    } catch (error) {
      debugPrint('打开媒体失败: ${PlaybackLogBuffer.sanitize(error.toString())}');
      _dumpLibmpvLogs();
      if (_canUsePlayer(generation)) {
        _playerError = AppFailure.playbackOpen;
        notifyListeners();
      }
    }
  }

  Future<void> _finishOpen(Duration? start, int generation) async {
    try {
      if (!_canUsePlayer(generation)) return;
      await subtitles.applyStyle();
      if (!_canUsePlayer(generation)) return;
      await _restoreProgressIfNeeded(start, generation);
      if (!_canUsePlayer(generation)) return;
      _startProgressSaveTimer();
      onPlaybackActivity?.call();
    } catch (error) {
      debugPrint('恢复播放状态失败: ${PlaybackLogBuffer.sanitize(error.toString())}');
      if (_canUsePlayer(generation)) {
        _playerError = AppFailure.playbackOpen;
        notifyListeners();
      }
    }
  }

  static PlaybackOptions optionsFor(AppSettings settings) => PlaybackOptions(
    cacheMaxBytes: settings.playbackCacheMaxBytes,
    readaheadSeconds: settings.playbackReadaheadSeconds,
    hardwareAcceleration: settings.enableHardwareAcceleration,
    subtitleLanguagePriority: settings.normalizedSubtitleLanguagePriority,
  );

  Future<void> _restoreProgressIfNeeded(Duration? resumePosition, int generation) async {
    if (_hasRestoredPosition || resumePosition == null) return;
    if (!_canUsePlayer(generation)) return;
    _hasRestoredPosition = true;
    await engine.seek(resumePosition);
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 500), () async {
        if (!_canUsePlayer(generation)) return;
        final currentPosition = engine.state.position;
        if (currentPosition.inMilliseconds < resumePosition.inMilliseconds - 2000) {
          await engine.seek(resumePosition);
        }
      }),
    );
    _showResumePositionNotice(resumePosition);
  }

  void _showResumePositionNotice(Duration position) {
    if (_isDisposed || _isClosing) return;
    _resumeNoticeTimer?.cancel();
    _showResumeNotice = true;
    _resumePositionLabel = MediaFormat.clockDuration(position);
    notifyListeners();
    _resumeNoticeTimer = Timer(const Duration(seconds: 6), () {
      if (_isDisposed || _isClosing) return;
      _showResumeNotice = false;
      notifyListeners();
    });
  }

  void _startProgressSaveTimer() {
    if (_isDisposed || _isClosing) return;
    _progressSaveTimer?.cancel();
    _progressSaveTimer = Timer.periodic(_progressSaveInterval, (_) => unawaited(_saveProgress()));
  }

  Future<void> _saveProgress({bool force = false, bool allowDisposed = false}) async {
    if ((_isDisposed || _isClosing) && !allowDisposed) return;
    final positionMs = engine.state.position.inMilliseconds;
    final durationMs = engine.state.duration.inMilliseconds;
    if (positionMs <= 0 && durationMs <= 0) return;
    try {
      await _session.saveProgress(positionMs: positionMs, durationMs: durationMs, force: force);
    } catch (error) {
      debugPrint('保存播放进度失败: $error');
    }
  }

  Future<void> prepareClose() async {
    _isClosing = true;
    _hasFlushedProgress = true;
    _nextMediaOpenGeneration();
    _progressSaveTimer?.cancel();
    await _session.prepareClose();
  }

  Future<void> shutdown() => _shutdown ??= _releasePlayer();

  Future<void> _releasePlayer() async {
    _isClosing = true;
    _session.beginShutdown();
    _nextMediaOpenGeneration();
    _progressSaveTimer?.cancel();
    _bufferingIndicatorTimer?.cancel();
    _resumeNoticeTimer?.cancel();
    try {
      await Future.wait([subtitles.shutdown(), ..._subscriptions.map((subscription) => subscription.cancel())]);
    } finally {
      await _session.close();
    }
  }

  Future<void> _handlePlaybackCompleted() async {
    await _saveProgress(force: true);
    if (!_isDisposed && hasNext) await playQueueOffset(1);
  }

  void _setBuffering(bool buffering) {
    if (_isBuffering == buffering) return;
    _isBuffering = buffering;
    _bufferingIndicatorTimer?.cancel();
    _bufferingIndicatorTimer = null;

    if (!buffering) {
      _isBufferingIndicatorVisible = false;
      return;
    }

    final delay = bufferingIndicatorDelayFor(_session.currentUrl ?? '');
    if (delay == Duration.zero) {
      _isBufferingIndicatorVisible = true;
      return;
    }

    _isBufferingIndicatorVisible = false;
    _bufferingIndicatorTimer = Timer(delay, () {
      if (_isDisposed || _isClosing || !_isBuffering) return;
      _isBufferingIndicatorVisible = true;
      notifyListeners();
    });
  }

  void _resetMediaState() {
    subtitles.resetForMedia();
    _setBuffering(false);
    _hasRestoredPosition = false;
    _hasFlushedProgress = false;
    _showResumeNotice = false;
    _resumePositionLabel = null;
    _playerError = null;
    _audioTracks = const [];
    _selectedAudioTrack = const PlaybackAudioTrack.automatic();
  }

  List<PlaybackAudioTrack> _normalizeAudioTracks(List<PlaybackAudioTrack> tracks) {
    final result = <PlaybackAudioTrack>[];
    for (final track in tracks) {
      if (track.isAutomatic || track.isDisabled) continue;
      if (!result.contains(track)) result.add(track);
    }
    return result;
  }

  PlaybackAudioTrack _resolveDisplayedAudioTrack(PlaybackAudioTrack selectedTrack, List<PlaybackAudioTrack> tracks) {
    if (tracks.isEmpty || tracks.contains(selectedTrack)) return selectedTrack;
    return tracks.firstWhere((track) => track.isDefault == true, orElse: () => tracks.first);
  }

  int _nextMediaOpenGeneration() {
    subtitles.invalidatePendingOperations();
    engine.cancelPendingCommands();
    return ++_mediaOpenGeneration;
  }

  bool _canUsePlayer([int? generation]) =>
      !_isDisposed && !_isClosing && (generation == null || generation == _mediaOpenGeneration);

  void _dumpLibmpvLogs() {
    final entries = _playbackLogs.snapshot();
    if (entries.isEmpty) {
      debugPrint('libmpv 日志上下文为空');
      return;
    }
    debugPrint('libmpv 最近 ${entries.length} 条日志：');
    for (final entry in entries) {
      debugPrint(entry);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _nextMediaOpenGeneration();
    if (!_hasFlushedProgress) {
      unawaited(_saveProgress(force: true, allowDisposed: true));
    }
    unawaited(shutdown().catchError((Object error) => debugPrint('播放器资源释放失败: $error')));
    subtitles.removeListener(_relaySubtitleState);
    subtitles.dispose();
    super.dispose();
  }
}
