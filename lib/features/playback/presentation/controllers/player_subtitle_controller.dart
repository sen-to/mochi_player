import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:mochi_player/features/playback/application/playback_engine.dart';
import 'package:mochi_player/features/playback/domain/playback_track.dart';

/// Owns subtitle selection, external-file identity and presentation state.
/// Borrows the session's engine; never opens, stops or disposes it.
class PlayerSubtitleController extends ChangeNotifier {
  PlayerSubtitleController({
    required this.engine,
    required this.languagePriority,
    required bool Function() canControlPlayback,
    this.onPlaybackActivity,
  }) : _canControlPlayback = canControlPlayback {
    _subscriptions.addAll([
      engine.stream.tracks.listen((tracks) {
        if (!this.canControlPlayback) return;
        _subtitleTracks = _normalizeSubtitleTracks(tracks.subtitle);
        _selectedSubtitleTrack = _resolveDisplayedSubtitleTrack(_selectedSubtitleTrack, _subtitleTracks);
        _syncPendingExternalSubtitleSelection();
        notifyListeners();
        if (!_didAutoSelectSubtitle) _autoSelectSubtitle();
      }),
      engine.stream.track.listen((track) {
        if (!this.canControlPlayback) return;
        if (!track.subtitle.isAutomatic) {
          _selectedSubtitleTrack = _resolveDisplayedSubtitleTrack(track.subtitle, _subtitleTracks);
        }
        _syncPendingExternalSubtitleSelection();
        notifyListeners();
      }),
      engine.stream.subtitle.listen((text) {
        if (!this.canControlPlayback) return;
        _subtitle = text;
        notifyListeners();
      }),
    ]);
  }

  final PlaybackEngine engine;
  final String languagePriority;
  final bool Function() _canControlPlayback;
  final VoidCallback? onPlaybackActivity;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final Map<String, _LoadedExternalSubtitle> _loadedExternalSubtitles = {};
  bool _isDisposed = false;
  Future<void>? _shutdown;
  int _mediaGeneration = 0;
  bool _didAutoSelectSubtitle = false;
  bool _overrideEmbeddedSubtitleStyle = false;
  String? _pendingExternalSubtitlePath;
  List<String> _subtitle = const [];
  List<PlaybackSubtitleTrack> _subtitleTracks = const [];
  PlaybackSubtitleTrack _selectedSubtitleTrack = const PlaybackSubtitleTrack.automatic();

  bool get canControlPlayback => !_isDisposed && _shutdown == null && _canControlPlayback();
  List<String> get subtitle => _subtitle;
  List<PlaybackSubtitleTrack> get subtitleTracks => _subtitleTracks;
  PlaybackSubtitleTrack get selectedSubtitleTrack => _selectedSubtitleTrack;
  bool get overrideEmbeddedSubtitleStyle => _overrideEmbeddedSubtitleStyle;

  /// Invalidates asynchronous work before preparing a different media item.
  void invalidatePendingOperations() => _mediaGeneration++;

  /// Clears per-media selection; the user's style preference survives a switch.
  void resetForMedia() {
    invalidatePendingOperations();
    _didAutoSelectSubtitle = false;
    _subtitle = const [];
    _subtitleTracks = const [];
    _selectedSubtitleTrack = const PlaybackSubtitleTrack.automatic();
    _pendingExternalSubtitlePath = null;
    _loadedExternalSubtitles.clear();
    notifyListeners();
  }

  Future<void> applyStyle() async {
    if (canControlPlayback) await engine.setSubtitleStyleOverride(_overrideEmbeddedSubtitleStyle);
  }

  bool _canComplete(int generation) => canControlPlayback && generation == _mediaGeneration;

  Future<void> setSubtitleTrack(PlaybackSubtitleTrack track) async {
    if (!canControlPlayback) return;
    final generation = _mediaGeneration;
    _didAutoSelectSubtitle = true;
    _selectedSubtitleTrack = track;
    notifyListeners();
    try {
      await engine.setSubtitleTrack(track);
      if (!_canComplete(generation)) return;
      await applyStyle();
    } catch (error) {
      debugPrint('切换字幕失败: $error');
    }
    if (_canComplete(generation)) onPlaybackActivity?.call();
  }

  /// Loads an external subtitle file for the media currently playing.
  ///
  /// The player publishes the loaded subtitle as a normal track update, which
  /// is the single source of truth for the subtitle menu.
  Future<bool> loadExternalSubtitle(String path) async {
    if (!canControlPlayback || path.trim().isEmpty) return false;

    final generation = _mediaGeneration;
    final normalizedPath = ExternalSubtitleTrack.normalizePath(path);
    final previousLoad = _loadedExternalSubtitles[normalizedPath];
    if (previousLoad != null) {
      final loadedTrack = previousLoad.track ?? _findSubtitleTrackByTitle(previousLoad.title, _subtitleTracks);
      if (loadedTrack != null) {
        previousLoad.track = loadedTrack;
        await setSubtitleTrack(loadedTrack);
      }
      return _canComplete(generation);
    }

    final track = ExternalSubtitleTrack.fromPath(normalizedPath);
    _didAutoSelectSubtitle = true;
    _loadedExternalSubtitles[normalizedPath] = _LoadedExternalSubtitle(title: track.title!);
    _pendingExternalSubtitlePath = normalizedPath;
    try {
      await engine.setSubtitleTrack(track);
      if (!_canComplete(generation)) return false;
      _subtitleTracks = _normalizeSubtitleTracks(engine.state.tracks.subtitle);
      _syncPendingExternalSubtitleSelection();
      await applyStyle();
      if (!_canComplete(generation)) return false;
      notifyListeners();
      onPlaybackActivity?.call();
      return true;
    } catch (error) {
      if (!_canComplete(generation)) return false;
      _loadedExternalSubtitles.remove(normalizedPath);
      if (_pendingExternalSubtitlePath == normalizedPath) {
        _pendingExternalSubtitlePath = null;
      }
      debugPrint('加载外挂字幕失败: $error');
      return false;
    }
  }

  void setSubtitleStyleOverride(bool value) {
    if (!canControlPlayback || _overrideEmbeddedSubtitleStyle == value) return;
    _overrideEmbeddedSubtitleStyle = value;
    _subtitle = const [];
    notifyListeners();
    unawaited(applyStyle().catchError((Object error) => debugPrint('设置字幕样式失败: $error')));
    onPlaybackActivity?.call();
  }

  void cycleSubtitleTrack() {
    if (!canControlPlayback || _subtitleTracks.isEmpty) return;
    final currentIndex = _subtitleTracks.indexOf(_selectedSubtitleTrack);
    final nextIndex = currentIndex < 0 ? 0 : (currentIndex + 1) % _subtitleTracks.length;
    unawaited(setSubtitleTrack(_subtitleTracks[nextIndex]));
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

  PlaybackSubtitleTrack _resolveDisplayedSubtitleTrack(
    PlaybackSubtitleTrack selectedTrack,
    List<PlaybackSubtitleTrack> tracks,
  ) {
    if (tracks.isEmpty || tracks.contains(selectedTrack)) return selectedTrack;
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

    final preferences = languagePriority
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

  Future<void> shutdown() => _shutdown ??= _cancelSubscriptions();

  Future<void> _cancelSubscriptions() async {
    invalidatePendingOperations();
    await Future.wait(_subscriptions.map((subscription) => subscription.cancel()));
    _subscriptions.clear();
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(shutdown());
    super.dispose();
  }
}

class _LoadedExternalSubtitle {
  _LoadedExternalSubtitle({required this.title});

  final String title;
  PlaybackSubtitleTrack? track;
}

/// Creates player tracks for subtitle files chosen outside the media source.
abstract final class ExternalSubtitleTrack {
  /// Produces a stable key for a file selected on the current platform.
  static String normalizePath(String value) => path.normalize(value.trim());

  /// The format is deliberately left to libmpv. Its supported subtitle
  /// demuxers depend on the bundled FFmpeg build and are broader than a fixed
  /// UI extension list.
  static PlaybackSubtitleTrack fromPath(String value) {
    final path = normalizePath(value);
    if (path.isEmpty || path == '.') {
      throw ArgumentError.value(value, 'path', '字幕文件路径不能为空');
    }

    final fileName = path.split(RegExp(r'[/\\]')).last;
    final extension = _extension(fileName);
    final title = extension.isEmpty ? fileName : fileName.substring(0, fileName.length - extension.length - 1);
    return PlaybackSubtitleTrack.externalFile(path, title: title);
  }

  static String _extension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return '';
    return path.substring(dot + 1).toLowerCase();
  }
}
