import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mochi_player/features/playback/application/playback_engine.dart';
import 'package:mochi_player/features/playback/domain/playback_track.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/playback/playback_target.dart';
import 'package:mochi_player/core/formatters/media_format.dart';
import 'package:mochi_player/features/playback/application/external_subtitle_track.dart';
import 'package:mochi_player/features/playback/application/playback_media_store.dart';
import 'package:mochi_player/features/playback/application/playback_session_controller.dart';
import 'package:mochi_player/features/playback/domain/playback_resume_policy.dart';
import 'package:mochi_player/features/playback/infrastructure/libmpv_log_buffer.dart';
import 'package:mochi_player/features/settings/domain/app_settings.dart';

/// Owns the playback engine and the playback state presented by [PlayerPage].
///
/// Queue and URL resolution remain in [PlaybackSessionController]. Window
/// modes and widget-only interaction state deliberately remain outside.
class PlayerPlaybackController extends ChangeNotifier {
  static const Duration _progressSaveInterval = Duration(seconds: 10);
  static const Duration localBufferingIndicatorDelay = Duration(milliseconds: 350);

  PlayerPlaybackController({
    required PlaybackMediaStore mediaStore,
    required AppSettings settings,
    required MediaFile initialItem,
    required List<MediaFile> queueItems,
    required PlaybackTarget initialTarget,
    required this.engine,
    this.onPlaybackActivity,
  }) : _settings = settings,
       _session = PlaybackSessionController(
         mediaStore: mediaStore,
         initialItem: initialItem,
         queueItems: queueItems,
         initialTarget: initialTarget,
       ) {
    _bindPlayerStreams();
  }

  final AppSettings _settings;
  final PlaybackSessionController _session;
  final VoidCallback? onPlaybackActivity;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final LibmpvLogBuffer _libmpvLogs = LibmpvLogBuffer();

  final PlaybackEngine engine;

  Timer? _progressSaveTimer;
  Timer? _resumeNoticeTimer;
  bool _isDisposed = false;
  bool _isClosing = false;
  Future<void>? _flushInFlight;
  Future<void>? _shutdown;
  bool _hasRestoredPosition = false;
  bool _hasFlushedProgress = false;
  bool _didAutoSelectSubtitle = false;
  bool _isBuffering = false;
  bool _isBufferingIndicatorVisible = false;
  Timer? _bufferingIndicatorTimer;
  bool _showResumeNotice = false;
  bool _overrideEmbeddedSubtitleStyle = false;
  int _mediaOpenGeneration = 0;
  double _lastVolumeBeforeMute = 100;
  String? _playerError;
  String? _resumePositionLabel;
  String? _pendingExternalSubtitlePath;
  final Map<String, _LoadedExternalSubtitle> _loadedExternalSubtitles = {};
  List<String> _subtitle = const [];
  List<PlaybackAudioTrack> _audioTracks = const [];
  List<PlaybackSubtitleTrack> _subtitleTracks = const [];
  PlaybackAudioTrack _selectedAudioTrack = const PlaybackAudioTrack.automatic();
  PlaybackSubtitleTrack _selectedSubtitleTrack = const PlaybackSubtitleTrack.automatic();

  MediaFile get currentItem => _session.currentItem;

  bool get hasPrevious => _session.hasPrevious;

  bool get hasNext => _session.hasNext;

  bool get isBuffering => _isBufferingIndicatorVisible;

  @visibleForTesting
  static Duration bufferingIndicatorDelayFor(String mediaUrl) {
    final scheme = Uri.tryParse(mediaUrl)?.scheme.toLowerCase();
    return scheme == 'http' || scheme == 'https' ? Duration.zero : localBufferingIndicatorDelay;
  }

  bool get showResumeNotice => _showResumeNotice;

  bool get overrideEmbeddedSubtitleStyle => _overrideEmbeddedSubtitleStyle;

  String? get playerError => _playerError;

  String? get resumePositionLabel => _resumePositionLabel;

  List<String> get subtitle => _subtitle;

  List<PlaybackAudioTrack> get audioTracks => _audioTracks;

  List<PlaybackSubtitleTrack> get subtitleTracks => _subtitleTracks;

  PlaybackAudioTrack get selectedAudioTrack => _selectedAudioTrack;

  PlaybackSubtitleTrack get selectedSubtitleTrack => _selectedSubtitleTrack;

  Future<void> initialize() => _openMedia(_nextMediaOpenGeneration());

  void clearError() {
    if (_playerError == null || _isDisposed) return;
    _playerError = null;
    notifyListeners();
  }

  Future<void> playQueueOffset(int offset) async {
    if (_isDisposed || _isClosing || _session.isSwitching) return;

    final generation = _nextMediaOpenGeneration();
    _setBuffering(true);
    _playerError = null;
    _showResumeNotice = false;
    notifyListeners();

    final move = await _session.moveBy(
      offset,
      positionMs: engine.state.position.inMilliseconds,
      durationMs: engine.state.duration.inMilliseconds,
    );
    if (!_canUsePlayer(generation)) return;

    if (move == null) {
      _setBuffering(false);
      notifyListeners();
      return;
    }
    if (!move.isReady) {
      _setBuffering(false);
      _playerError = '获取播放链接失败: ${move.item.fileName}';
      notifyListeners();
      return;
    }

    _resumeNoticeTimer?.cancel();
    _resetMediaState();
    notifyListeners();
    await _openMedia(generation);
  }

  Future<bool> setAudioTrack(PlaybackAudioTrack track) async {
    if (_isDisposed || _isClosing) return false;
    _selectedAudioTrack = track;
    notifyListeners();
    try {
      await engine.setAudioTrack(track);
    } catch (error) {
      debugPrint('切换音轨失败: $error');
      return false;
    }
    if (_isDisposed || _isClosing) return false;
    onPlaybackActivity?.call();
    return true;
  }

  Future<void> setSubtitleTrack(PlaybackSubtitleTrack track) async {
    if (_isDisposed || _isClosing) return;
    _didAutoSelectSubtitle = true;
    _selectedSubtitleTrack = track;
    notifyListeners();
    try {
      await engine.setSubtitleTrack(track);
      await _applySubtitleStyleMode();
    } catch (error) {
      debugPrint('切换字幕失败: $error');
    }
    if (!_isDisposed) onPlaybackActivity?.call();
  }

  /// Loads an external subtitle file for the media currently playing.
  ///
  /// The player publishes the loaded subtitle as a normal track update, which
  /// is the single source of truth for the subtitle menu.
  Future<bool> loadExternalSubtitle(String path) async {
    if (_isDisposed || _isClosing || path.trim().isEmpty) return false;

    final normalizedPath = ExternalSubtitleTrack.normalizePath(path);
    final previousLoad = _loadedExternalSubtitles[normalizedPath];
    if (previousLoad != null) {
      final loadedTrack = previousLoad.track ?? _findSubtitleTrackByTitle(previousLoad.title, _subtitleTracks);
      if (loadedTrack != null) {
        previousLoad.track = loadedTrack;
        await setSubtitleTrack(loadedTrack);
      }
      return true;
    }

    final track = ExternalSubtitleTrack.fromPath(normalizedPath);
    _didAutoSelectSubtitle = true;
    _loadedExternalSubtitles[normalizedPath] = _LoadedExternalSubtitle(title: track.title!);
    _pendingExternalSubtitlePath = normalizedPath;
    try {
      await engine.setSubtitleTrack(track);
      if (_isDisposed || _isClosing) return false;
      _subtitleTracks = _normalizeSubtitleTracks(engine.state.tracks.subtitle);
      _syncPendingExternalSubtitleSelection();
      await _applySubtitleStyleMode();
      notifyListeners();
      onPlaybackActivity?.call();
      return true;
    } catch (error) {
      _loadedExternalSubtitles.remove(normalizedPath);
      if (_pendingExternalSubtitlePath == normalizedPath) {
        _pendingExternalSubtitlePath = null;
      }
      debugPrint('加载外挂字幕失败: $error');
      return false;
    }
  }

  void setSubtitleStyleOverride(bool value) {
    if (_isDisposed || _isClosing || _overrideEmbeddedSubtitleStyle == value) return;
    _overrideEmbeddedSubtitleStyle = value;
    _subtitle = const [];
    notifyListeners();
    unawaited(_applySubtitleStyleMode());
    onPlaybackActivity?.call();
  }

  void cycleSubtitleTrack() {
    if (_isDisposed || _isClosing || _subtitleTracks.isEmpty) return;
    final currentIndex = _subtitleTracks.indexOf(_selectedSubtitleTrack);
    final nextIndex = currentIndex < 0 ? 0 : (currentIndex + 1) % _subtitleTracks.length;
    unawaited(setSubtitleTrack(_subtitleTracks[nextIndex]));
  }

  void cycleAudioTrack() {
    if (_isDisposed || _isClosing || _audioTracks.isEmpty) return;
    final currentIndex = _audioTracks.indexOf(_selectedAudioTrack);
    final nextIndex = currentIndex < 0 ? 0 : (currentIndex + 1) % _audioTracks.length;
    unawaited(setAudioTrack(_audioTracks[nextIndex]));
  }

  void adjustVolume(double delta) {
    if (_isDisposed || _isClosing) return;
    final nextVolume = (engine.state.volume + delta).clamp(0.0, 100.0);
    engine.setVolume(nextVolume);
    if (nextVolume > 0) _lastVolumeBeforeMute = nextVolume;
    onPlaybackActivity?.call();
  }

  void toggleMute() {
    if (_isDisposed || _isClosing) return;
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
        debugPrint('播放器错误: ${LibmpvLogBuffer.sanitize(error)}');
        _dumpLibmpvLogs();
        _playerError = LibmpvLogBuffer.sanitize(error);
        notifyListeners();
      }),
      engine.stream.log.listen((log) {
        if (!_isDisposed) _libmpvLogs.add(log);
      }),
      engine.stream.tracks.listen((tracks) {
        if (_isDisposed || _isClosing) return;
        _audioTracks = _normalizeAudioTracks(tracks.audio);
        _subtitleTracks = _normalizeSubtitleTracks(tracks.subtitle);
        _selectedAudioTrack = _resolveDisplayedAudioTrack(_selectedAudioTrack, _audioTracks);
        _selectedSubtitleTrack = _resolveDisplayedSubtitleTrack(_selectedSubtitleTrack, _subtitleTracks);
        _syncPendingExternalSubtitleSelection();
        notifyListeners();
        if (!_didAutoSelectSubtitle) _autoSelectSubtitle();
      }),
      engine.stream.track.listen((track) {
        if (_isDisposed || _isClosing) return;
        if (!track.audio.isAutomatic) {
          _selectedAudioTrack = track.audio;
        }
        if (!track.subtitle.isAutomatic) {
          _selectedSubtitleTrack = _resolveDisplayedSubtitleTrack(track.subtitle, _subtitleTracks);
        }
        _syncPendingExternalSubtitleSelection();
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
      engine.stream.subtitle.listen((subtitle) {
        if (_isDisposed || _isClosing) return;
        _subtitle = subtitle;
        notifyListeners();
      }),
    ]);
  }

  Future<void> _openMedia(int generation) async {
    await _session.refreshCurrentItem();
    if (!_canUsePlayer(generation)) return;
    final resumePosition = PlaybackResumePolicy.positionFor(currentItem, hasRestoredPosition: _hasRestoredPosition);

    debugPrint('正在打开媒体播放目标：${_safeTargetDescription(_session.currentTarget.url)}');
    await _applyPlayerSettings(generation);
    if (!_canUsePlayer(generation)) return;
    await _applySubtitleStyleMode(generation);
    if (!_canUsePlayer(generation)) return;

    try {
      await engine.open(_session.currentTarget, start: resumePosition);
      if (!_canUsePlayer(generation)) return;
      await _applySubtitleStyleMode(generation);
      if (!_canUsePlayer(generation)) return;
      await _restoreProgressIfNeeded(resumePosition, generation);
      if (!_canUsePlayer(generation)) return;
      _startProgressSaveTimer();
      onPlaybackActivity?.call();
    } catch (error) {
      debugPrint('打开媒体失败: ${LibmpvLogBuffer.sanitize(error.toString())}');
      _dumpLibmpvLogs();
      if (_canUsePlayer(generation)) {
        _playerError = LibmpvLogBuffer.sanitize(error.toString());
        notifyListeners();
      }
    }
  }

  static String _safeTargetDescription(String url) {
    final scheme = Uri.tryParse(url)?.scheme.toLowerCase();
    return switch (scheme) {
      'file' => '本地文件',
      'http' || 'https' => 'HTTP 流',
      'smb' => 'SMB 流',
      final value when value != null && value.isNotEmpty => '$value 播放目标',
      _ => '未知播放目标',
    };
  }

  Future<void> _applyPlayerSettings([int? generation]) async {
    if (!_canUsePlayer(generation)) return;
    await engine.applyOptions(optionsFor(_settings));
  }

  static PlaybackOptions optionsFor(AppSettings settings) => PlaybackOptions(
    cacheMaxBytes: settings.playbackCacheMaxBytes,
    readaheadSeconds: settings.playbackReadaheadSeconds,
    hardwareAcceleration: settings.enableHardwareAcceleration,
    subtitleLanguagePriority: settings.normalizedSubtitleLanguagePriority,
  );

  Future<void> _applySubtitleStyleMode([int? generation]) async {
    if (!_canUsePlayer(generation)) return;
    await engine.setSubtitleStyleOverride(_overrideEmbeddedSubtitleStyle);
  }

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

  Future<void> _saveProgress({bool force = false, bool allowDisposed = false, bool propagateFailure = false}) async {
    if ((_isDisposed || _isClosing) && !allowDisposed) return;
    final positionMs = engine.state.position.inMilliseconds;
    final durationMs = engine.state.duration.inMilliseconds;
    if (positionMs <= 0 && durationMs <= 0) return;
    try {
      await _session.saveProgress(positionMs: positionMs, durationMs: durationMs, force: force);
    } catch (error) {
      debugPrint('保存播放进度失败: $error');
      if (propagateFailure) rethrow;
    }
  }

  /// Persists the latest player snapshot before a window is closed.
  Future<void> flushProgress() => _flushInFlight ??= _flushProgress();

  Future<void> _flushProgress() async {
    _hasFlushedProgress = true;
    await _saveProgress(force: true, allowDisposed: true, propagateFailure: true);
    await _session.drainProgress();
  }

  Future<void> prepareClose() async {
    _isClosing = true;
    _session.beginShutdown();
    _nextMediaOpenGeneration();
    _progressSaveTimer?.cancel();
    // Pause before taking the final snapshot. In-flight open/seek callbacks are
    // invalidated above and cannot restart a session during shutdown.
    try {
      await engine.pause();
    } finally {
      await flushProgress();
    }
  }

  Future<void> shutdown() => _shutdown ??= _releasePlayer();

  Future<void> _releasePlayer() async {
    _isClosing = true;
    _nextMediaOpenGeneration();
    _progressSaveTimer?.cancel();
    _bufferingIndicatorTimer?.cancel();
    _resumeNoticeTimer?.cancel();
    await Future.wait(_subscriptions.map((subscription) => subscription.cancel()));
    await engine.dispose();
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

    final delay = bufferingIndicatorDelayFor(_session.currentTarget.url);
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
    _setBuffering(false);
    _hasRestoredPosition = false;
    _hasFlushedProgress = false;
    _flushInFlight = null;
    _didAutoSelectSubtitle = false;
    _showResumeNotice = false;
    _resumePositionLabel = null;
    _playerError = null;
    _subtitle = const [];
    _audioTracks = const [];
    _subtitleTracks = const [];
    _pendingExternalSubtitlePath = null;
    _loadedExternalSubtitles.clear();
    _selectedAudioTrack = const PlaybackAudioTrack.automatic();
    _selectedSubtitleTrack = const PlaybackSubtitleTrack.automatic();
  }

  List<PlaybackSubtitleTrack> _normalizeSubtitleTracks(List<PlaybackSubtitleTrack> tracks) {
    final result = <PlaybackSubtitleTrack>[const PlaybackSubtitleTrack.disabled()];
    for (final track in tracks) {
      if (track.isAutomatic || track.isDisabled) continue;
      if (!result.contains(track)) result.add(track);
    }
    return result;
  }

  void _syncPendingExternalSubtitleSelection() {
    final path = _pendingExternalSubtitlePath;
    if (path == null) return;

    final loadedSubtitle = _loadedExternalSubtitles[path];
    if (loadedSubtitle == null) return;
    final track = _findSubtitleTrackByTitle(loadedSubtitle.title, _subtitleTracks);
    if (track == null) return;

    loadedSubtitle.track = track;
    _selectedSubtitleTrack = track;
    _pendingExternalSubtitlePath = null;
  }

  PlaybackSubtitleTrack? _findSubtitleTrackByTitle(String title, List<PlaybackSubtitleTrack> tracks) {
    for (final track in tracks) {
      if (track.title?.trim() == title) return track;
    }
    return null;
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

  PlaybackSubtitleTrack _resolveDisplayedSubtitleTrack(
    PlaybackSubtitleTrack selectedTrack,
    List<PlaybackSubtitleTrack> tracks,
  ) {
    if (tracks.contains(selectedTrack)) return selectedTrack;
    final selectedTitle = selectedTrack.title?.trim();
    if (selectedTitle != null && selectedTitle.isNotEmpty) {
      for (final track in tracks) {
        if (track.title?.trim() == selectedTitle) return track;
      }
    }
    return tracks.firstWhere((track) => !track.isDisabled && track.isDefault == true, orElse: () => tracks.first);
  }

  void _autoSelectSubtitle() {
    final availableTracks = _subtitleTracks.where((track) => !track.isDisabled).toList();
    if (availableTracks.isEmpty) return;

    final preferences = _settings.normalizedSubtitleLanguagePriority
        .split(',')
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty);
    for (final preference in preferences) {
      for (final track in availableTracks) {
        if (_trackMatchesLanguage(track, preference)) {
          unawaited(setSubtitleTrack(track));
          return;
        }
      }
    }
  }

  bool _trackMatchesLanguage(PlaybackSubtitleTrack track, String preference) {
    final text = [track.language, track.title].whereType<String>().join(' ').toLowerCase();
    if (text.contains(preference)) return true;
    if (_isChineseLanguage(preference)) {
      return const ['zh', 'chi', 'zho', 'chs', 'cht', '中文', '简', '繁'].any(text.contains);
    }
    if (preference == 'ja' || preference == 'jpn') {
      return const ['ja', 'jpn', 'japanese', '日语', '日文'].any(text.contains);
    }
    if (preference == 'en' || preference == 'eng') {
      return const ['en', 'eng', 'english', '英语', '英文'].any(text.contains);
    }
    return false;
  }

  bool _isChineseLanguage(String value) =>
      const ['zh', 'chi', 'zho', 'chs', 'cht'].contains(value) || value.startsWith('zh-');

  int _nextMediaOpenGeneration() {
    engine.cancelPendingCommands();
    return ++_mediaOpenGeneration;
  }

  bool _canUsePlayer([int? generation]) =>
      !_isDisposed && !_isClosing && (generation == null || generation == _mediaOpenGeneration);

  void _dumpLibmpvLogs() {
    final entries = _libmpvLogs.snapshot();
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
    super.dispose();
  }
}

class _LoadedExternalSubtitle {
  _LoadedExternalSubtitle({required this.title});

  final String title;
  PlaybackSubtitleTrack? track;
}
