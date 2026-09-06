import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/playback/playback_target.dart';
import 'package:mochi_player/core/formatters/media_format.dart';
import 'package:mochi_player/features/playback/application/external_subtitle_track.dart';
import 'package:mochi_player/features/playback/application/playback_media_store.dart';
import 'package:mochi_player/features/playback/application/playback_session_controller.dart';
import 'package:mochi_player/features/playback/domain/playback_resume_policy.dart';
import 'package:mochi_player/features/playback/infrastructure/libmpv_log_buffer.dart';
import 'package:mochi_player/features/settings/domain/app_settings.dart';

/// Owns media_kit and the playback state presented by [PlayerPage].
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
    this.onPlaybackActivity,
  }) : _settings = settings,
       _session = PlaybackSessionController(
         mediaStore: mediaStore,
         initialItem: initialItem,
         queueItems: queueItems,
         initialTarget: initialTarget,
       ) {
    player = Player(
      configuration: PlayerConfiguration(
        title: 'Mochi Player',
        bufferSize: settings.playbackCacheMaxBytes,
        libass: true,
        logLevel: MPVLogLevel.info,
      ),
    );
    videoController = VideoController(
      player,
      configuration: VideoControllerConfiguration(enableHardwareAcceleration: settings.enableHardwareAcceleration),
    );
    _bindPlayerStreams();
  }

  final AppSettings _settings;
  final PlaybackSessionController _session;
  final VoidCallback? onPlaybackActivity;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final LibmpvLogBuffer _libmpvLogs = LibmpvLogBuffer();

  late final Player player;
  late final VideoController videoController;

  Timer? _progressSaveTimer;
  Timer? _resumeNoticeTimer;
  bool _isDisposed = false;
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
  List<AudioTrack> _audioTracks = const [];
  List<SubtitleTrack> _subtitleTracks = const [];
  AudioTrack _selectedAudioTrack = const AudioTrack('auto', null, null);
  SubtitleTrack _selectedSubtitleTrack = const SubtitleTrack('auto', null, null);

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

  List<AudioTrack> get audioTracks => _audioTracks;

  List<SubtitleTrack> get subtitleTracks => _subtitleTracks;

  AudioTrack get selectedAudioTrack => _selectedAudioTrack;

  SubtitleTrack get selectedSubtitleTrack => _selectedSubtitleTrack;

  Future<void> initialize() => _openMedia(_nextMediaOpenGeneration());

  void clearError() {
    if (_playerError == null || _isDisposed) return;
    _playerError = null;
    notifyListeners();
  }

  Future<void> playQueueOffset(int offset) async {
    if (_isDisposed || _session.isSwitching) return;

    final generation = _nextMediaOpenGeneration();
    _setBuffering(true);
    _playerError = null;
    _showResumeNotice = false;
    notifyListeners();

    final move = await _session.moveBy(
      offset,
      positionMs: player.state.position.inMilliseconds,
      durationMs: player.state.duration.inMilliseconds,
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

  Future<bool> setAudioTrack(AudioTrack track) async {
    if (_isDisposed) return false;
    _selectedAudioTrack = track;
    notifyListeners();
    try {
      await player.setAudioTrack(track);
    } catch (error) {
      debugPrint('切换音轨失败: $error');
      return false;
    }
    if (_isDisposed) return false;
    onPlaybackActivity?.call();
    return true;
  }

  Future<void> setSubtitleTrack(SubtitleTrack track) async {
    if (_isDisposed) return;
    _didAutoSelectSubtitle = true;
    _selectedSubtitleTrack = track;
    notifyListeners();
    try {
      await player.setSubtitleTrack(track);
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
    if (_isDisposed || path.trim().isEmpty) return false;

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
      await player.setSubtitleTrack(track);
      if (_isDisposed) return false;
      _subtitleTracks = _normalizeSubtitleTracks(player.state.tracks.subtitle);
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
    if (_isDisposed || _overrideEmbeddedSubtitleStyle == value) return;
    _overrideEmbeddedSubtitleStyle = value;
    _subtitle = const [];
    notifyListeners();
    unawaited(_applySubtitleStyleMode());
    onPlaybackActivity?.call();
  }

  void cycleSubtitleTrack() {
    if (_isDisposed || _subtitleTracks.isEmpty) return;
    final currentIndex = _subtitleTracks.indexOf(_selectedSubtitleTrack);
    final nextIndex = currentIndex < 0 ? 0 : (currentIndex + 1) % _subtitleTracks.length;
    unawaited(setSubtitleTrack(_subtitleTracks[nextIndex]));
  }

  void cycleAudioTrack() {
    if (_isDisposed || _audioTracks.isEmpty) return;
    final currentIndex = _audioTracks.indexOf(_selectedAudioTrack);
    final nextIndex = currentIndex < 0 ? 0 : (currentIndex + 1) % _audioTracks.length;
    unawaited(setAudioTrack(_audioTracks[nextIndex]));
  }

  void adjustVolume(double delta) {
    if (_isDisposed) return;
    final nextVolume = (player.state.volume + delta).clamp(0.0, 100.0);
    player.setVolume(nextVolume);
    if (nextVolume > 0) _lastVolumeBeforeMute = nextVolume;
    onPlaybackActivity?.call();
  }

  void toggleMute() {
    if (_isDisposed) return;
    final currentVolume = player.state.volume;
    if (currentVolume > 0) {
      _lastVolumeBeforeMute = currentVolume;
      player.setVolume(0);
    } else {
      player.setVolume(_lastVolumeBeforeMute <= 0 ? 100 : _lastVolumeBeforeMute);
    }
    onPlaybackActivity?.call();
  }

  void _bindPlayerStreams() {
    _subscriptions.addAll([
      player.stream.error.listen((error) {
        if (_isDisposed) return;
        debugPrint('播放器错误: ${LibmpvLogBuffer.sanitize(error)}');
        _dumpLibmpvLogs();
        _playerError = LibmpvLogBuffer.sanitize(error);
        notifyListeners();
      }),
      player.stream.log.listen((log) {
        if (!_isDisposed) _libmpvLogs.add(log);
      }),
      player.stream.tracks.listen((tracks) {
        if (_isDisposed) return;
        _audioTracks = _normalizeAudioTracks(tracks.audio);
        _subtitleTracks = _normalizeSubtitleTracks(tracks.subtitle);
        _selectedAudioTrack = _resolveDisplayedAudioTrack(_selectedAudioTrack, _audioTracks);
        _selectedSubtitleTrack = _resolveDisplayedSubtitleTrack(_selectedSubtitleTrack, _subtitleTracks);
        _syncPendingExternalSubtitleSelection();
        notifyListeners();
        if (!_didAutoSelectSubtitle) _autoSelectSubtitle();
      }),
      player.stream.track.listen((track) {
        if (_isDisposed) return;
        if (!_isAudioTrackAuto(track.audio)) {
          _selectedAudioTrack = track.audio;
        }
        if (!_isSubtitleTrackAuto(track.subtitle)) {
          _selectedSubtitleTrack = _resolveDisplayedSubtitleTrack(track.subtitle, _subtitleTracks);
        }
        _syncPendingExternalSubtitleSelection();
        notifyListeners();
      }),
      player.stream.buffering.listen((buffering) {
        if (_isDisposed) return;
        _setBuffering(buffering);
        notifyListeners();
      }),
      player.stream.playing.listen((_) {
        if (!_isDisposed) onPlaybackActivity?.call();
      }),
      player.stream.completed.listen((completed) {
        if (!_isDisposed && completed) unawaited(_handlePlaybackCompleted());
      }),
      player.stream.subtitle.listen((subtitle) {
        if (_isDisposed) return;
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

    final media = Media(
      _session.currentTarget.url,
      httpHeaders: {'User-Agent': 'MochiPlayer/1.0.0', ..._session.currentTarget.httpHeaders},
      start: resumePosition,
    );
    try {
      await player.open(media, play: true);
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
    if (!_canUsePlayer(generation) || player.platform is! NativePlayer) return;
    final platform = player.platform as NativePlayer;
    final properties = <String, String>{
      'cache': 'yes',
      'cache-pause': 'yes',
      'cache-pause-wait': '3',
      'cache-secs': _settings.playbackReadaheadSeconds.toString(),
      'demuxer-readahead-secs': _settings.playbackReadaheadSeconds.toString(),
      'demuxer-max-bytes': _settings.playbackCacheMaxBytes.toString(),
      'demuxer-max-back-bytes': (_settings.playbackCacheMaxBytes ~/ 4).toString(),
      'hwdec': _settings.enableHardwareAcceleration ? 'auto' : 'no',
      'slang': _settings.normalizedSubtitleLanguagePriority,
      'vo-profile': 'high-quality',
    };
    for (final entry in properties.entries) {
      if (!_canUsePlayer(generation)) return;
      try {
        await platform.setProperty(entry.key, entry.value);
      } catch (error) {
        debugPrint('应用播放器设置失败 ${entry.key}=${entry.value}: $error');
      }
    }
  }

  Future<void> _applySubtitleStyleMode([int? generation]) async {
    if (!_canUsePlayer(generation) || player.platform is! NativePlayer) return;
    final platform = player.platform as NativePlayer;
    final value = _overrideEmbeddedSubtitleStyle ? 'no' : 'yes';
    final properties = <String, String>{'sub-ass': value, 'sub-visibility': value, 'secondary-sub-visibility': value};
    for (final entry in properties.entries) {
      if (!_canUsePlayer(generation)) return;
      try {
        await platform.setProperty(entry.key, entry.value);
      } catch (error) {
        debugPrint('应用字幕样式模式失败 ${entry.key}=${entry.value}: $error');
      }
    }
  }

  Future<void> _restoreProgressIfNeeded(Duration? resumePosition, int generation) async {
    if (_hasRestoredPosition || resumePosition == null) return;
    if (!_canUsePlayer(generation)) return;
    _hasRestoredPosition = true;
    await player.seek(resumePosition);
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 500), () async {
        if (!_canUsePlayer(generation)) return;
        final currentPosition = player.state.position;
        if (currentPosition.inMilliseconds < resumePosition.inMilliseconds - 2000) {
          await player.seek(resumePosition);
        }
      }),
    );
    _showResumePositionNotice(resumePosition);
  }

  void _showResumePositionNotice(Duration position) {
    if (_isDisposed) return;
    _resumeNoticeTimer?.cancel();
    _showResumeNotice = true;
    _resumePositionLabel = MediaFormat.clockDuration(position);
    notifyListeners();
    _resumeNoticeTimer = Timer(const Duration(seconds: 6), () {
      if (_isDisposed) return;
      _showResumeNotice = false;
      notifyListeners();
    });
  }

  void _startProgressSaveTimer() {
    if (_isDisposed) return;
    _progressSaveTimer?.cancel();
    _progressSaveTimer = Timer.periodic(_progressSaveInterval, (_) => unawaited(_saveProgress()));
  }

  Future<void> _saveProgress({bool force = false, bool allowDisposed = false}) async {
    if (_isDisposed && !allowDisposed) return;
    final positionMs = player.state.position.inMilliseconds;
    final durationMs = player.state.duration.inMilliseconds;
    if (positionMs <= 0 && durationMs <= 0) return;
    try {
      await _session.saveProgress(positionMs: positionMs, durationMs: durationMs, force: force);
    } catch (error) {
      debugPrint('保存播放进度失败: $error');
    }
  }

  /// Persists the latest player snapshot before a window is closed.
  Future<void> flushProgress() async {
    if (_hasFlushedProgress) return;
    // Set the latch before awaiting I/O so disposal cannot schedule a second
    // forced write while this final snapshot is still being persisted.
    _hasFlushedProgress = true;
    await _saveProgress(force: true);
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
      if (_isDisposed || !_isBuffering) return;
      _isBufferingIndicatorVisible = true;
      notifyListeners();
    });
  }

  void _resetMediaState() {
    _setBuffering(false);
    _hasRestoredPosition = false;
    _hasFlushedProgress = false;
    _didAutoSelectSubtitle = false;
    _showResumeNotice = false;
    _resumePositionLabel = null;
    _playerError = null;
    _subtitle = const [];
    _audioTracks = const [];
    _subtitleTracks = const [];
    _pendingExternalSubtitlePath = null;
    _loadedExternalSubtitles.clear();
    _selectedAudioTrack = const AudioTrack('auto', null, null);
    _selectedSubtitleTrack = const SubtitleTrack('auto', null, null);
  }

  List<SubtitleTrack> _normalizeSubtitleTracks(List<SubtitleTrack> tracks) {
    final result = <SubtitleTrack>[const SubtitleTrack('no', null, null)];
    for (final track in tracks) {
      if (_isSubtitleTrackAuto(track) || _isSubtitleTrackOff(track)) continue;
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

  SubtitleTrack? _findSubtitleTrackByTitle(String title, List<SubtitleTrack> tracks) {
    for (final track in tracks) {
      if (track.title?.trim() == title) return track;
    }
    return null;
  }

  List<AudioTrack> _normalizeAudioTracks(List<AudioTrack> tracks) {
    final result = <AudioTrack>[];
    for (final track in tracks) {
      if (_isAudioTrackAuto(track) || _isAudioTrackOff(track)) continue;
      if (!result.contains(track)) result.add(track);
    }
    return result;
  }

  AudioTrack _resolveDisplayedAudioTrack(AudioTrack selectedTrack, List<AudioTrack> tracks) {
    if (tracks.isEmpty || tracks.contains(selectedTrack)) return selectedTrack;
    return tracks.firstWhere((track) => track.isDefault == true, orElse: () => tracks.first);
  }

  SubtitleTrack _resolveDisplayedSubtitleTrack(SubtitleTrack selectedTrack, List<SubtitleTrack> tracks) {
    if (tracks.contains(selectedTrack)) return selectedTrack;
    final selectedTitle = selectedTrack.title?.trim();
    if (selectedTitle != null && selectedTitle.isNotEmpty) {
      for (final track in tracks) {
        if (track.title?.trim() == selectedTitle) return track;
      }
    }
    return tracks.firstWhere(
      (track) => !_isSubtitleTrackOff(track) && track.isDefault == true,
      orElse: () => tracks.first,
    );
  }

  void _autoSelectSubtitle() {
    final availableTracks = _subtitleTracks.where((track) => !_isSubtitleTrackOff(track)).toList();
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

  bool _trackMatchesLanguage(SubtitleTrack track, String preference) {
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

  bool _isSubtitleTrackAuto(SubtitleTrack track) => track.id == 'auto' && !track.uri && !track.data;

  bool _isSubtitleTrackOff(SubtitleTrack track) => track.id == 'no' && !track.uri && !track.data;

  bool _isAudioTrackAuto(AudioTrack track) => track.id == 'auto' && !track.uri;

  bool _isAudioTrackOff(AudioTrack track) => track.id == 'no' && !track.uri;

  int _nextMediaOpenGeneration() => ++_mediaOpenGeneration;

  bool _canUsePlayer([int? generation]) => !_isDisposed && (generation == null || generation == _mediaOpenGeneration);

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
    _progressSaveTimer?.cancel();
    _bufferingIndicatorTimer?.cancel();
    _resumeNoticeTimer?.cancel();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(player.dispose());
    super.dispose();
  }
}

class _LoadedExternalSubtitle {
  _LoadedExternalSubtitle({required this.title});

  final String title;
  SubtitleTrack? track;
}
