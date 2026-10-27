import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/playback/application/playback_engine.dart';
import 'package:mochi_player/features/playback/domain/playback_track.dart';
import 'package:mochi_player/features/playback/presentation/widgets/player_overlay.dart';
import 'package:mochi_player/features/playback/presentation/widgets/player_popup_menu.dart';
import 'package:mochi_player/features/playback/presentation/widgets/player_seek_bar.dart';
import 'package:mochi_player/l10n/l10n.dart';

class PlayerControls extends StatefulWidget {
  final PlaybackEngine engine;
  final String title;
  final String? secondaryTitle;
  final bool isVisible;
  final bool isFullScreen;
  final bool isMiniPlayer;
  final bool isMiniPlayerAlwaysOnTop;
  final VoidCallback onToggleFullScreen;

  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onPip;
  final VoidCallback? onToggleMiniPlayerAlwaysOnTop;
  final ValueChanged<Rect>? onControlBarBoundsChanged;
  final List<PlaybackAudioTrack> audioTracks;
  final PlaybackAudioTrack? selectedAudioTrack;
  final ValueChanged<PlaybackAudioTrack>? onAudioSelected;
  final List<PlaybackSubtitleTrack> subtitleTracks;
  final PlaybackSubtitleTrack? selectedSubtitleTrack;
  final ValueChanged<PlaybackSubtitleTrack>? onSubtitleSelected;
  final VoidCallback? onExternalSubtitleRequested;
  final bool overrideEmbeddedSubtitleStyle;
  final ValueChanged<bool>? onSubtitleStyleOverrideChanged;
  final ValueChanged<bool>? onMenuVisibilityChanged;

  /// Called as soon as a pointer presses a visible player control.
  final VoidCallback? onControlPointerDown;

  /// Called after a control interaction has finished.
  final VoidCallback? onInteraction;

  const PlayerControls({
    super.key,
    required this.engine,
    this.title = '',
    this.secondaryTitle,
    required this.isVisible,
    required this.isFullScreen,
    this.isMiniPlayer = false,
    this.isMiniPlayerAlwaysOnTop = false,
    required this.onToggleFullScreen,
    this.onPrevious,
    this.onNext,
    this.onPip,
    this.onToggleMiniPlayerAlwaysOnTop,
    this.onControlBarBoundsChanged,
    this.audioTracks = const [],
    this.selectedAudioTrack,
    this.onAudioSelected,
    this.subtitleTracks = const [],
    this.selectedSubtitleTrack,
    this.onSubtitleSelected,
    this.onExternalSubtitleRequested,
    this.overrideEmbeddedSubtitleStyle = false,
    this.onSubtitleStyleOverrideChanged,
    this.onMenuVisibilityChanged,
    this.onControlPointerDown,
    this.onInteraction,
  });

  @override
  State<PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<PlayerControls> {
  // 状态
  bool _isPlaying = false;
  double _volume = 100.0;
  double _rate = 1.0;
  String _cacheSpeed = '';

  // 资源
  Timer? _cacheSpeedTimer;
  final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.engine.state.playing;
    _volume = widget.engine.state.volume;
    _rate = widget.engine.state.rate;

    _subscriptions.addAll([
      widget.engine.stream.playing.listen((v) {
        if (mounted) setState(() => _isPlaying = v);
      }),
      widget.engine.stream.volume.listen((v) {
        if (mounted) setState(() => _volume = v);
      }),
      widget.engine.stream.rate.listen((v) {
        if (mounted) setState(() => _rate = v);
      }),
    ]);

    _syncCacheSpeedPolling();
  }

  @override
  void didUpdateWidget(covariant PlayerControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isVisible != widget.isVisible || oldWidget.isMiniPlayer != widget.isMiniPlayer) {
      _syncCacheSpeedPolling();
    }
  }

  bool get _shouldPollCacheSpeed => widget.isVisible && !widget.isMiniPlayer;

  void _syncCacheSpeedPolling() {
    _cacheSpeedTimer?.cancel();
    _cacheSpeedTimer = null;
    if (!_shouldPollCacheSpeed) return;

    unawaited(_updateCacheSpeed());
    _cacheSpeedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(_updateCacheSpeed());
    });
  }

  Future<void> _updateCacheSpeed() async {
    try {
      final bytesPerSecond = await widget.engine.readCacheBytesPerSecond();
      if (!mounted) return;
      final cacheSpeed = bytesPerSecond == null || !bytesPerSecond.isFinite || bytesPerSecond <= 0
          ? ''
          : _formatCacheSpeed(bytesPerSecond, context.l10n.localeName);
      if (mounted && cacheSpeed != _cacheSpeed) {
        setState(() => _cacheSpeed = cacheSpeed);
      }
    } catch (_) {
      // `cache-speed` is unavailable before a source is opened and for some local inputs.
    }
  }

  static String _formatCacheSpeed(double bytesPerSecond, String locale) {
    const bytesPerMegabyte = 1024 * 1024;
    if (bytesPerSecond >= bytesPerMegabyte) {
      return '${NumberFormat('0.0', locale).format(bytesPerSecond / bytesPerMegabyte)} MB/s';
    }
    return '${NumberFormat('0', locale).format(bytesPerSecond / 1024)} KB/s';
  }

  @override
  void dispose() {
    _cacheSpeedTimer?.cancel();
    for (var s in _subscriptions) {
      s.cancel();
    }
    super.dispose();
  }

  void _onTap(VoidCallback action) {
    widget.onInteraction?.call();
    action();
  }

  Widget _trackControlPointer(Widget child) {
    return Listener(
      behavior: HitTestBehavior.deferToChild,
      onPointerDown: (_) => widget.onControlPointerDown?.call(),
      onPointerUp: (_) => widget.onInteraction?.call(),
      onPointerCancel: (_) => widget.onInteraction?.call(),
      child: child,
    );
  }

  /// 驱动 0→1 的可见度，并把当前值交给控制层。
  ///
  /// 这里不能用 [AnimatedOpacity]：底部面板与 mini 播放器是玻璃材质，被透明度
  /// 层包住时 [BackdropFilter] 拿不到背景，模糊会在过渡期间消失、最后一帧才
  /// 跳到终态。它们改为自行渐入模糊半径（见 `_playerGlass`），其余内容则在滤镜
  /// 内部用透明度淡入。
  Widget _withVisibility(Widget Function(double t) builder) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: widget.isVisible ? 1 : 0),
      duration: PlayerOverlayLayout.visibilityDuration,
      curve: Curves.easeInOut,
      builder: (context, t, _) => IgnorePointer(ignoring: !widget.isVisible, child: builder(t)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMiniPlayer) {
      return _withVisibility(
        (t) => _trackControlPointer(
          Center(
            child: PlayerMiniControls(
              visibility: t,
              isPlaying: _isPlaying,
              isAlwaysOnTop: widget.isMiniPlayerAlwaysOnTop,
              onPlayPause: () => _onTap(widget.engine.playOrPause),
              onToggleAlwaysOnTop: () => _onTap(widget.onToggleMiniPlayerAlwaysOnTop ?? () {}),
              onRestoreWindow: () => _onTap(widget.onPip ?? () {}),
            ),
          ),
        ),
      );
    }

    final showVolumeSlider = MediaQuery.sizeOf(context).width > 1000;
    // Hoisted out of the visibility builder so that the per-frame fade does not
    // rebuild them.
    final topBar = PlayerTopBar(
      title: widget.title,
      secondaryTitle: widget.secondaryTitle,
      cacheSpeed: _cacheSpeed,
      isFullScreen: widget.isFullScreen,
    );
    final progress = PlayerSeekBar(engine: widget.engine);
    final controls = Row(
      children: [
        // Keep the content aligned with the Slider track instead
        // of its wider touch target.
        const SizedBox(width: AppSpacing.md),

        // 1. 当前进度优先放在左侧，紧接着才是播放控制。
        _DurationLabel(engine: widget.engine),
        const SizedBox(width: 16),

        // 2. 上一集
        if (widget.onPrevious != null) ...[
          PlayerControlButton(
            onPressed: () => _onTap(widget.onPrevious!),
            child: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 21),
          ),
          const SizedBox(width: 4),
        ],

        // 3. 快退
        PlayerControlButton(
          onPressed: () => _onTap(() => widget.engine.seek(widget.engine.state.position - const Duration(seconds: 10))),
          child: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 21),
        ),
        const SizedBox(width: 4),

        // 4. 播放/暂停 (统一大小，但保留图标视觉差异)
        PlayerControlButton(
          onPressed: () => _onTap(widget.engine.playOrPause),
          child: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 4),

        // 5. 快进
        PlayerControlButton(
          onPressed: () => _onTap(() => widget.engine.seek(widget.engine.state.position + const Duration(seconds: 10))),
          child: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 21),
        ),

        // 6. 下一集
        if (widget.onNext != null) ...[
          const SizedBox(width: 4),
          PlayerControlButton(
            onPressed: () => _onTap(widget.onNext!),
            child: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 21),
          ),
        ],
        const Spacer(),

        // 右侧功能区
        if (widget.onSubtitleSelected != null && widget.subtitleTracks.isNotEmpty) ...[
          _SubtitleMenuButton(
            tracks: widget.subtitleTracks,
            selectedTrack: widget.selectedSubtitleTrack,
            onExternalSubtitleRequested: widget.onExternalSubtitleRequested,
            overrideEmbeddedStyle: widget.overrideEmbeddedSubtitleStyle,
            onSelected: (track) {
              widget.onInteraction?.call();
              widget.onSubtitleSelected?.call(track);
            },
            onStyleOverrideChanged: (value) {
              widget.onInteraction?.call();
              widget.onSubtitleStyleOverrideChanged?.call(value);
            },
            onMenuVisibilityChanged: widget.onMenuVisibilityChanged,
          ),
          const SizedBox(width: 4),
        ],

        if (widget.onAudioSelected != null && widget.audioTracks.isNotEmpty) ...[
          _AudioMenuButton(
            tracks: widget.audioTracks,
            selectedTrack: widget.selectedAudioTrack,
            onMenuVisibilityChanged: widget.onMenuVisibilityChanged,
            onSelected: (track) {
              widget.onInteraction?.call();
              widget.onAudioSelected?.call(track);
            },
          ),
          const SizedBox(width: 4),
        ],

        _RateMenuButton(
          rate: _rate,
          onMenuVisibilityChanged: widget.onMenuVisibilityChanged,
          onSelected: (rate) {
            widget.onInteraction?.call();
            widget.engine.setRate(rate);
          },
        ),
        const SizedBox(width: 4),

        if (widget.onPip != null) ...[
          PlayerControlButton(
            onPressed: () => _onTap(widget.onPip!),
            child: const Icon(Icons.picture_in_picture_alt_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 4),
        ],

        // 音量
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlayerControlButton(
              onPressed: () => _onTap(() {
                final newVol = _volume > 0 ? 0.0 : 100.0;
                widget.engine.setVolume(newVol);
              }),
              child: Icon(
                _volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            if (showVolumeSlider)
              SizedBox(
                width: 72,
                height: 16,
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                    trackShape: const RectangularSliderTrackShape(),
                  ),
                  child: Slider(
                    value: _volume.clamp(0.0, 100.0),
                    min: 0.0,
                    max: 100.0,
                    onChanged: widget.engine.setVolume,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(width: 4),
        PlayerControlButton(
          onPressed: () => _onTap(widget.onToggleFullScreen),
          child: Icon(
            widget.isFullScreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
            color: Colors.white,
            size: 21,
          ),
        ),
      ],
    );

    return _withVisibility(
      (t) => _trackControlPointer(
        Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Opacity(opacity: t, child: topBar),
            ),

            Positioned.fill(
              child: PlayerBottomControlBar(
                visibility: t,
                onBoundsChanged: widget.onControlBarBoundsChanged,
                progress: progress,
                controls: controls,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RateMenuButton extends StatelessWidget {
  static final List<double> _rates = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  final double rate;
  final ValueChanged<double> onSelected;
  final ValueChanged<bool>? onMenuVisibilityChanged;

  const _RateMenuButton({required this.rate, required this.onSelected, this.onMenuVisibilityChanged});

  String _labelFor(BuildContext context, double value) {
    if (value == value.roundToDouble()) {
      return '${NumberFormat('0', context.l10n.localeName).format(value)}×';
    }
    return '${NumberFormat('0.0#', context.l10n.localeName).format(value)}×';
  }

  @override
  Widget build(BuildContext context) {
    return PlayerPopupMenuButton(
      menuWidth: 148,
      onVisibilityChanged: onMenuVisibilityChanged,
      menuBuilder: (context, close) => PlayerPopupMenuPanel(
        title: context.l10n.playbackSpeed,
        children: [
          for (final value in _rates)
            PlayerPopupMenuItem(
              label: _labelFor(context, value),
              selected: (rate - value).abs() < 0.01,
              onPressed: () {
                close();
                onSelected(value);
              },
            ),
        ],
      ),
      child: PlayerMenuButtonSurface(
        width: 42,
        child: Text(
          _labelFor(context, rate),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
            height: 1,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}

class _AudioMenuButton extends StatelessWidget {
  final List<PlaybackAudioTrack> tracks;
  final PlaybackAudioTrack? selectedTrack;
  final ValueChanged<PlaybackAudioTrack> onSelected;
  final ValueChanged<bool>? onMenuVisibilityChanged;

  const _AudioMenuButton({
    required this.tracks,
    required this.selectedTrack,
    required this.onSelected,
    this.onMenuVisibilityChanged,
  });

  String _labelFor(BuildContext context, PlaybackAudioTrack track) {
    final title = track.title?.trim();
    final language = track.language?.trim();
    final codec = track.codec?.trim();
    final channels = track.channels?.trim();
    final parts = <String>[];
    if (title != null && title.isNotEmpty) {
      parts.add(title);
    }
    if (language != null && language.isNotEmpty && title?.toLowerCase() != language.toLowerCase()) {
      parts.add(language);
    }
    if (codec != null && codec.isNotEmpty) {
      parts.add(codec.toUpperCase());
    }
    if (channels != null && channels.isNotEmpty) {
      parts.add(channels);
    }
    if (parts.isEmpty) {
      parts.add(context.l10n.audioTrackLabel(track.id));
    }
    return parts.join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    return PlayerPopupMenuButton(
      menuWidth: 240,
      onVisibilityChanged: onMenuVisibilityChanged,
      menuBuilder: (context, close) => PlayerPopupMenuPanel(
        title: context.l10n.audioTracks,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final track in tracks)
                    PlayerPopupMenuItem(
                      label: _labelFor(context, track),
                      selected: selectedTrack == track,
                      onPressed: () {
                        close();
                        onSelected(track);
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      child: PlayerMenuButtonSurface(child: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 18)),
    );
  }
}

class _SubtitleMenuButton extends StatelessWidget {
  final List<PlaybackSubtitleTrack> tracks;
  final PlaybackSubtitleTrack? selectedTrack;
  final VoidCallback? onExternalSubtitleRequested;
  final bool overrideEmbeddedStyle;
  final ValueChanged<PlaybackSubtitleTrack> onSelected;
  final ValueChanged<bool> onStyleOverrideChanged;
  final ValueChanged<bool>? onMenuVisibilityChanged;

  const _SubtitleMenuButton({
    required this.tracks,
    required this.selectedTrack,
    this.onExternalSubtitleRequested,
    required this.overrideEmbeddedStyle,
    required this.onSelected,
    required this.onStyleOverrideChanged,
    this.onMenuVisibilityChanged,
  });

  bool _isOff(PlaybackSubtitleTrack track) => track.isDisabled;

  String _labelFor(BuildContext context, PlaybackSubtitleTrack track) {
    if (_isOff(track)) return context.l10n.subtitlesOff;

    final title = track.title?.trim();
    final language = track.language?.trim();
    final parts = <String>[];
    if (title != null && title.isNotEmpty) {
      parts.add(title);
    }
    if (language != null && language.isNotEmpty && title?.toLowerCase() != language.toLowerCase()) {
      parts.add(language);
    }
    if (parts.isEmpty) {
      parts.add(context.l10n.subtitleTrackLabel(track.id));
    }
    return parts.join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    return PlayerPopupMenuButton(
      menuWidth: 280,
      onVisibilityChanged: onMenuVisibilityChanged,
      menuBuilder: (context, close) => PlayerPopupMenuPanel(
        title: context.l10n.subtitles,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final track in tracks)
                    PlayerPopupMenuItem(
                      label: _labelFor(context, track),
                      selected: selectedTrack == track,
                      onPressed: () {
                        close();
                        onSelected(track);
                      },
                    ),
                  if (onExternalSubtitleRequested != null) ...[
                    const PlayerPopupMenuDivider(),
                    PlayerPopupMenuItem(
                      label: context.l10n.loadExternalSubtitle,
                      onPressed: () {
                        close();
                        onExternalSubtitleRequested!();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const PlayerPopupMenuDivider(),
          PlayerPopupMenuSwitchItem(
            title: context.l10n.mochiSubtitleStyle,
            subtitle: context.l10n.mochiSubtitleStyleDescription,
            value: overrideEmbeddedStyle,
            onChanged: onStyleOverrideChanged,
          ),
        ],
      ),
      child: PlayerMenuButtonSurface(child: const Icon(Icons.closed_caption_rounded, color: Colors.white, size: 18)),
    );
  }
}

// ================== 时间标签 ==================
String _formatPlaybackDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return duration.inHours > 0 ? '${duration.inHours}:$minutes:$seconds' : '$minutes:$seconds';
}

class _DurationLabel extends StatelessWidget {
  final PlaybackEngine engine;

  const _DurationLabel({required this.engine});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: engine.stream.position,
      builder: (_, snap) => Text(
        '${_formatPlaybackDuration(snap.data ?? Duration.zero)} / '
        '${_formatPlaybackDuration(engine.state.duration)}',
        style: const TextStyle(color: Colors.white70, fontSize: 12, fontFeatures: [FontFeature.tabularFigures()]),
      ),
    );
  }
}
