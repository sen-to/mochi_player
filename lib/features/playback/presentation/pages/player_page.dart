import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/media/media_type.dart';
import 'package:mochi_player/core/domain/playback/playback_target.dart';
import 'package:mochi_player/core/platform/window_controls_controller.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/playback/application/playback_media_store.dart';
import 'package:mochi_player/features/playback/presentation/controllers/player_playback_controller.dart';
import 'package:mochi_player/features/playback/presentation/controllers/player_window_close_coordinator.dart';
import 'package:mochi_player/features/playback/presentation/controllers/player_window_mode_controller.dart';
import 'package:mochi_player/features/playback/presentation/widgets/player_controls.dart';
import 'package:mochi_player/features/playback/presentation/widgets/player_overlay.dart';
import 'package:mochi_player/features/settings/application/app_settings_provider.dart';
import 'package:mochi_player/features/settings/domain/app_settings.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

class PlayerPage extends StatefulWidget {
  final MediaFile videoItem;
  final PlaybackTarget target;
  final String? contextTitle;
  final List<MediaFile> playlist;
  final PlaybackMediaStore mediaStore;
  final PlayerWindowCloseCoordinator closeCoordinator;
  final Size regularMinimumWindowSize;

  const PlayerPage({
    super.key,
    required this.videoItem,
    required this.target,
    this.contextTitle,
    this.playlist = const [],
    required this.mediaStore,
    required this.closeCoordinator,
    required this.regularMinimumWindowSize,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  static const _controlsAutoHideDelay = Duration(seconds: 4);

  late final AppSettings _playbackSettings;
  late final PlayerPlaybackController _playbackController;
  late final PlayerWindowModeController _windowModeController;

  final FocusNode _focusNode = FocusNode();
  Timer? _hideControlsTimer;
  bool _isControlsVisible = true;
  bool _isPlayerMenuOpen = false;
  bool _isDisposed = false;
  Rect? _controlBarBounds;

  MediaFile get _currentItem => _playbackController.currentItem;

  String get _displayTitle {
    if (widget.contextTitle != null && _currentItem.mediaType == MediaType.episode) {
      return widget.contextTitle!;
    }
    return _currentItem.parsedTitle.isNotEmpty ? _currentItem.parsedTitle : _currentItem.fileName;
  }

  String? get _displaySecondaryTitle {
    if (_currentItem.mediaType != MediaType.episode) return null;
    final season = _currentItem.parsedSeason;
    final episode = _currentItem.parsedEpisode;
    if (season == null || episode == null) return null;
    return '第 $season 季 · 第 $episode 集';
  }

  @override
  void initState() {
    super.initState();
    _playbackSettings = context.read<AppSettingsProvider>().settings;
    final queueItems = widget.playlist.isNotEmpty ? widget.playlist : [widget.videoItem];

    _playbackController = PlayerPlaybackController(
      mediaStore: widget.mediaStore,
      settings: _playbackSettings,
      initialItem: widget.videoItem,
      queueItems: queueItems,
      initialTarget: widget.target,
      onPlaybackActivity: _startHideControlsTimer,
    )..addListener(_handlePlaybackChanged);
    widget.closeCoordinator.registerProgressFlusher(_playbackController.flushProgress);
    _windowModeController = PlayerWindowModeController(
      windowControlsController: context.read<WindowControlsController>(),
      regularMinimumWindowSize: widget.regularMinimumWindowSize,
    )..addListener(_handleWindowModeChanged);

    unawaited(_playbackController.initialize());
    unawaited(_windowModeController.initialize());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDisposed) return;
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  void _handlePlaybackChanged() {
    if (mounted && !_isDisposed) setState(() {});
  }

  void _handleWindowModeChanged() {
    if (!mounted || _isDisposed) return;
    setState(() => _controlBarBounds = null);
    _startHideControlsTimer();
  }

  void _startHideControlsTimer() {
    if (_isDisposed) return;
    _hideControlsTimer?.cancel();
    if (_isPlayerMenuOpen) return;
    _hideControlsTimer = Timer(_controlsAutoHideDelay, () {
      if (mounted && !_isPlayerMenuOpen) {
        setState(() => _isControlsVisible = false);
      }
    });
  }

  void _pauseHideControlsTimer() {
    if (_isDisposed) return;
    _hideControlsTimer?.cancel();
  }

  void _setPlayerMenuVisibility(bool isOpen) {
    if (_isDisposed || _isPlayerMenuOpen == isOpen) return;
    _isPlayerMenuOpen = isOpen;
    _hideControlsTimer?.cancel();
    if (isOpen) {
      if (mounted && !_isControlsVisible) {
        setState(() => _isControlsVisible = true);
      }
      return;
    }
    _startHideControlsTimer();
  }

  void _setControlBarBounds(Rect bounds) {
    if (_isDisposed || _windowModeController.isMiniPlayer || _controlBarBounds == bounds) {
      return;
    }
    setState(() => _controlBarBounds = bounds);
  }

  void _onPointerHover(PointerEvent event) {
    if (_isDisposed) return;
    if (!_isControlsVisible) setState(() => _isControlsVisible = true);
    _startHideControlsTimer();
  }

  void _onPointerExit(PointerEvent event) {
    if (_isDisposed || _isPlayerMenuOpen) return;
    _hideControlsTimer?.cancel();
    if (mounted) setState(() => _isControlsVisible = false);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (_isDisposed || event is! KeyDownEvent) return KeyEventResult.handled;

    final player = _playbackController.player;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.keyK) {
      player.playOrPause();
    } else if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyJ) {
      player.seek(player.state.position - const Duration(seconds: 10));
    } else if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.keyL) {
      player.seek(player.state.position + const Duration(seconds: 10));
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _playbackController.adjustVolume(5);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _playbackController.adjustVolume(-5);
    } else if (key == LogicalKeyboardKey.keyM) {
      _playbackController.toggleMute();
    } else if (key == LogicalKeyboardKey.keyF) {
      _windowModeController.toggleFullScreen();
    } else if (key == LogicalKeyboardKey.keyC) {
      _playbackController.cycleSubtitleTrack();
    } else if (key == LogicalKeyboardKey.keyA) {
      _playbackController.cycleAudioTrack();
    } else if (key == LogicalKeyboardKey.escape && _windowModeController.isFullScreen) {
      unawaited(_windowModeController.exitFullScreen());
    }
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _hideControlsTimer?.cancel();
    _playbackController.removeListener(_handlePlaybackChanged);
    widget.closeCoordinator.unregisterProgressFlusher();
    _playbackController.dispose();
    _windowModeController.removeListener(_handleWindowModeChanged);
    unawaited(_windowModeController.restoreWindow().whenComplete(_windowModeController.dispose));
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subtitleFontSize = PlayerSubtitleSizing.fontSize(
      configuredFontSize: _playbackSettings.subtitleFontSize,
      viewportSize: MediaQuery.sizeOf(context),
    );
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: MouseRegion(
          onHover: _onPointerHover,
          onExit: _onPointerExit,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Video(
                controller: _playbackController.videoController,
                controls: (state) => const SizedBox.shrink(),
                subtitleViewConfiguration: const SubtitleViewConfiguration(
                  style: TextStyle(fontSize: 0, color: Colors.transparent),
                ),
              ),
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanStart: Theme.of(context).platform == TargetPlatform.windows
                      ? null
                      : (_) => unawaited(windowManager.startDragging()),
                  onDoubleTap: _windowModeController.toggleFullScreen,
                  child: const ColoredBox(color: Colors.transparent),
                ),
              ),
              if (_playbackController.isBuffering)
                const Center(child: SizedBox(width: 44, height: 44, child: CircularProgressIndicator(strokeWidth: 3))),
              if (_playbackController.playerError case final error?)
                Positioned(
                  left: 24,
                  right: 24,
                  top: 72,
                  child: _PlayerMessage(
                    icon: Icons.error_outline_rounded,
                    message: error,
                    actionLabel: '关闭',
                    onAction: _playbackController.clearError,
                  ),
                ),
              if (_playbackController.showResumeNotice && _playbackController.playerError == null)
                Positioned(
                  left: 24,
                  right: 24,
                  top: 72,
                  child: _PlayerMessage(
                    icon: Icons.history_rounded,
                    message: '已从 ${_playbackController.resumePositionLabel ?? '上次进度'} 继续播放',
                  ),
                ),
              if (_playbackController.overrideEmbeddedSubtitleStyle)
                Positioned.fill(
                  child: PlayerSubtitleAvoidingControls(
                    controlsVisible: _isControlsVisible,
                    isMiniPlayer: _windowModeController.isMiniPlayer,
                    controlBarBounds: _controlBarBounds,
                    child: IgnorePointer(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final line in _playbackController.subtitle)
                            Text(
                              line,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: subtitleFontSize,
                                height: 1.25,
                                color: Colors.white,
                                shadows: const [Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1))],
                              ),
                              textHeightBehavior: const TextHeightBehavior(
                                applyHeightToFirstAscent: false,
                                applyHeightToLastDescent: false,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              PlayerControls(
                player: _playbackController.player,
                title: _displayTitle,
                secondaryTitle: _displaySecondaryTitle,
                isVisible: _isControlsVisible,
                isFullScreen: _windowModeController.isFullScreen,
                isMiniPlayer: _windowModeController.isMiniPlayer,
                isMiniPlayerAlwaysOnTop: _windowModeController.isMiniPlayerAlwaysOnTop,
                onToggleFullScreen: _windowModeController.toggleFullScreen,
                onPrevious: _playbackController.hasPrevious
                    ? () => unawaited(_playbackController.playQueueOffset(-1))
                    : null,
                onNext: _playbackController.hasNext ? () => unawaited(_playbackController.playQueueOffset(1)) : null,
                onPip: _windowModeController.toggleMiniPlayer,
                onToggleMiniPlayerAlwaysOnTop: _windowModeController.toggleMiniPlayerAlwaysOnTop,
                onControlBarBoundsChanged: _setControlBarBounds,
                audioTracks: _playbackController.audioTracks,
                selectedAudioTrack: _playbackController.selectedAudioTrack,
                onAudioSelected: (track) {
                  unawaited(_playbackController.setAudioTrack(track));
                },
                subtitleTracks: _playbackController.subtitleTracks,
                selectedSubtitleTrack: _playbackController.selectedSubtitleTrack,
                onExternalSubtitleRequested: () => unawaited(_loadExternalSubtitle()),
                overrideEmbeddedSubtitleStyle: _playbackController.overrideEmbeddedSubtitleStyle,
                onSubtitleStyleOverrideChanged: _playbackController.setSubtitleStyleOverride,
                onMenuVisibilityChanged: _setPlayerMenuVisibility,
                onSubtitleSelected: (track) {
                  unawaited(_playbackController.setSubtitleTrack(track));
                },
                onControlPointerDown: _pauseHideControlsTimer,
                onInteraction: _startHideControlsTimer,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadExternalSubtitle() async {
    const subtitleFiles = XTypeGroup(label: '字幕文件', extensions: ['srt', 'ass', 'ssa', 'vtt']);

    try {
      final selectedFile = await openFile(acceptedTypeGroups: [subtitleFiles]);
      if (selectedFile == null || !mounted) return;

      final loaded = await _playbackController.loadExternalSubtitle(selectedFile.path);
      if (!loaded && mounted) {
        AppMessage.error('无法加载所选字幕文件');
      }
    } catch (error, stackTrace) {
      debugPrint('选择外挂字幕失败: $error\n$stackTrace');
      if (mounted) AppMessage.error('无法加载所选字幕文件');
    }
  }
}

class _PlayerMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _PlayerMessage({required this.icon, required this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha((255 * 0.72).round()),
          borderRadius: BorderRadius.circular(AppRadii.full),
          border: Border.all(color: Colors.white.withAlpha((255 * 0.12).round())),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(width: 12),
              AppButton(
                onPressed: onAction,
                label: actionLabel!,
                variant: AppButtonVariant.secondary,
                appearance: AppAppearance.overlay,
                size: AppButtonSize.compact,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
