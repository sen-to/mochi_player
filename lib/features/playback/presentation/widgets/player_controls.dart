import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/playback/presentation/widgets/player_overlay.dart';
import 'package:mochi_player/features/playback/presentation/widgets/player_popup_menu.dart';
import 'package:mochi_player/features/playback/presentation/widgets/player_seek_time_preview.dart';

class PlayerControls extends StatefulWidget {
  final Player player;
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
  final List<AudioTrack> audioTracks;
  final AudioTrack? selectedAudioTrack;
  final ValueChanged<AudioTrack>? onAudioSelected;
  final List<SubtitleTrack> subtitleTracks;
  final SubtitleTrack? selectedSubtitleTrack;
  final ValueChanged<SubtitleTrack>? onSubtitleSelected;
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
    required this.player,
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
    _isPlaying = widget.player.state.playing;
    _volume = widget.player.state.volume;
    _rate = widget.player.state.rate;

    _subscriptions.addAll([
      widget.player.stream.playing.listen((v) {
        if (mounted) setState(() => _isPlaying = v);
      }),
      widget.player.stream.volume.listen((v) {
        if (mounted) setState(() => _volume = v);
      }),
      widget.player.stream.rate.listen((v) {
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
    final platform = widget.player.platform;
    if (platform is! NativePlayer) return;

    try {
      final bytesPerSecond = double.tryParse(await platform.getProperty('cache-speed'));
      final cacheSpeed = bytesPerSecond == null || !bytesPerSecond.isFinite || bytesPerSecond <= 0
          ? ''
          : _formatCacheSpeed(bytesPerSecond);
      if (mounted && cacheSpeed != _cacheSpeed) {
        setState(() => _cacheSpeed = cacheSpeed);
      }
    } catch (_) {
      // `cache-speed` is unavailable before a source is opened and for some local inputs.
    }
  }

  static String _formatCacheSpeed(double bytesPerSecond) {
    const bytesPerMegabyte = 1024 * 1024;
    if (bytesPerSecond >= bytesPerMegabyte) {
      return '${(bytesPerSecond / bytesPerMegabyte).toStringAsFixed(1)} MB/s';
    }
    return '${(bytesPerSecond / 1024).toStringAsFixed(0)} KB/s';
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

  Widget _withVisibility(Widget child) {
    return AnimatedOpacity(
      opacity: widget.isVisible ? 1 : 0,
      duration: PlayerOverlayLayout.visibilityDuration,
      curve: Curves.easeInOut,
      child: IgnorePointer(ignoring: !widget.isVisible, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMiniPlayer) {
      return _withVisibility(
        _trackControlPointer(
          Center(
            child: PlayerMiniControls(
              isPlaying: _isPlaying,
              isAlwaysOnTop: widget.isMiniPlayerAlwaysOnTop,
              onPlayPause: () => _onTap(widget.player.playOrPause),
              onToggleAlwaysOnTop: () => _onTap(widget.onToggleMiniPlayerAlwaysOnTop ?? () {}),
              onRestoreWindow: () => _onTap(widget.onPip ?? () {}),
            ),
          ),
        ),
      );
    }

    final showVolumeSlider = MediaQuery.sizeOf(context).width > 1000;
    return _withVisibility(
      _trackControlPointer(
        Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: PlayerTopBar(
                title: widget.title,
                secondaryTitle: widget.secondaryTitle,
                cacheSpeed: _cacheSpeed,
                isFullScreen: widget.isFullScreen,
              ),
            ),

            Positioned.fill(
              child: PlayerBottomControlBar(
                onBoundsChanged: widget.onControlBarBoundsChanged,
                progress: _VideoSeekBar(player: widget.player),
                controls: Row(
                  children: [
                    // Keep the content aligned with the Slider track instead
                    // of its wider touch target.
                    const SizedBox(width: AppSpacing.md),

                    // 1. 当前进度优先放在左侧，紧接着才是播放控制。
                    _DurationLabel(player: widget.player),
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
                      onPressed: () =>
                          _onTap(() => widget.player.seek(widget.player.state.position - const Duration(seconds: 10))),
                      child: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 21),
                    ),
                    const SizedBox(width: 4),

                    // 4. 播放/暂停 (统一大小，但保留图标视觉差异)
                    PlayerControlButton(
                      onPressed: () => _onTap(widget.player.playOrPause),
                      child: Icon(
                        _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 4),

                    // 5. 快进
                    PlayerControlButton(
                      onPressed: () =>
                          _onTap(() => widget.player.seek(widget.player.state.position + const Duration(seconds: 10))),
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
                        widget.player.setRate(rate);
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
                            widget.player.setVolume(newVol);
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
                                onChanged: widget.player.setVolume,
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RateMenuButton extends StatelessWidget {
  static const List<double> _rates = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  final double rate;
  final ValueChanged<double> onSelected;
  final ValueChanged<bool>? onMenuVisibilityChanged;

  const _RateMenuButton({required this.rate, required this.onSelected, this.onMenuVisibilityChanged});

  String _labelFor(double value) {
    if (value == value.roundToDouble()) {
      return '${value.toInt()}×';
    }
    return '${value.toStringAsFixed(2).replaceAll(RegExp(r'0$'), '')}×';
  }

  @override
  Widget build(BuildContext context) {
    return PlayerPopupMenuButton(
      menuWidth: 148,
      onVisibilityChanged: onMenuVisibilityChanged,
      menuBuilder: (context, close) => PlayerPopupMenuPanel(
        title: '播放速度',
        children: [
          for (final value in _rates)
            PlayerPopupMenuItem(
              label: _labelFor(value),
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
          _labelFor(rate),
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
  final List<AudioTrack> tracks;
  final AudioTrack? selectedTrack;
  final ValueChanged<AudioTrack> onSelected;
  final ValueChanged<bool>? onMenuVisibilityChanged;

  const _AudioMenuButton({
    required this.tracks,
    required this.selectedTrack,
    required this.onSelected,
    this.onMenuVisibilityChanged,
  });

  String _labelFor(AudioTrack track) {
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
      parts.add('音轨 ${track.id}');
    }
    return parts.join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    return PlayerPopupMenuButton(
      menuWidth: 240,
      onVisibilityChanged: onMenuVisibilityChanged,
      menuBuilder: (context, close) => PlayerPopupMenuPanel(
        title: '音轨',
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final track in tracks)
                    PlayerPopupMenuItem(
                      label: _labelFor(track),
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
  final List<SubtitleTrack> tracks;
  final SubtitleTrack? selectedTrack;
  final VoidCallback? onExternalSubtitleRequested;
  final bool overrideEmbeddedStyle;
  final ValueChanged<SubtitleTrack> onSelected;
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

  bool _isOff(SubtitleTrack track) => track.id == 'no' && !track.uri && !track.data;

  String _labelFor(SubtitleTrack track) {
    if (_isOff(track)) return '关闭字幕';

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
      parts.add('字幕 ${track.id}');
    }
    return parts.join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    return PlayerPopupMenuButton(
      menuWidth: 280,
      onVisibilityChanged: onMenuVisibilityChanged,
      menuBuilder: (context, close) => PlayerPopupMenuPanel(
        title: '字幕',
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final track in tracks)
                    PlayerPopupMenuItem(
                      label: _labelFor(track),
                      selected: selectedTrack == track,
                      onPressed: () {
                        close();
                        onSelected(track);
                      },
                    ),
                  if (onExternalSubtitleRequested != null) ...[
                    const PlayerPopupMenuDivider(),
                    PlayerPopupMenuItem(
                      label: '加载外挂字幕…',
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
            title: '使用 Mochi 字幕样式',
            subtitle: '忽略字幕文件自带的字体与颜色',
            value: overrideEmbeddedStyle,
            onChanged: onStyleOverrideChanged,
          ),
        ],
      ),
      child: PlayerMenuButtonSurface(child: const Icon(Icons.closed_caption_rounded, color: Colors.white, size: 18)),
    );
  }
}

// ================== 进度条 ==================
class _VideoSeekBar extends StatefulWidget {
  final Player player;

  const _VideoSeekBar({required this.player});

  @override
  State<_VideoSeekBar> createState() => _VideoSeekBarState();
}

class _VideoSeekBarState extends State<_VideoSeekBar> {
  static const double _trackHorizontalInset = AppSpacing.md;
  static const double _previewVerticalOffset = 34;

  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;
  Duration _buf = Duration.zero;
  bool _dragging = false;
  Duration? _previewPosition;
  Offset? _previewOffset;
  OverlayEntry? _previewOverlay;
  late List<StreamSubscription> _subs;

  @override
  void initState() {
    super.initState();
    _dur = widget.player.state.duration;
    _subs = [
      widget.player.stream.position.listen((p) {
        if (!_dragging && mounted) setState(() => _pos = p);
      }),
      widget.player.stream.duration.listen((d) {
        if (mounted) setState(() => _dur = d);
      }),
      widget.player.stream.buffer.listen((b) {
        if (mounted) setState(() => _buf = b);
      }),
    ];
  }

  @override
  void dispose() {
    _hidePreview();
    for (var s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  void _showPreview(double value) {
    final renderBox = context.findRenderObject();
    if (renderBox is! RenderBox || !renderBox.hasSize) return;

    final usableWidth = (renderBox.size.width - _trackHorizontalInset * 2).clamp(0.0, double.infinity);
    final fraction = _dur.inMilliseconds == 0 ? 0.0 : (value / _dur.inMilliseconds).clamp(0.0, 1.0);
    _previewPosition = Duration(milliseconds: value.round());
    _previewOffset = renderBox.localToGlobal(Offset(_trackHorizontalInset + usableWidth * fraction, 0));

    final existingOverlay = _previewOverlay;
    if (existingOverlay != null) {
      existingOverlay.markNeedsBuild();
      return;
    }

    final overlay = OverlayEntry(
      builder: (context) => Positioned(
        left: (_previewOffset ?? Offset.zero).dx,
        top: (_previewOffset ?? Offset.zero).dy - _previewVerticalOffset,
        child: IgnorePointer(
          child: FractionalTranslation(
            translation: const Offset(-0.5, 0),
            child: PlayerSeekTimePreview(position: _previewPosition ?? Duration.zero),
          ),
        ),
      ),
    );
    // OverlayEntry.mounted becomes true on a later frame. Use ownership of
    // the entry as the synchronous insertion guard: repeated pointer events
    // in that frame must rebuild the same entry, never insert it twice.
    _previewOverlay = overlay;
    Overlay.of(context, rootOverlay: true).insert(overlay);
  }

  void _hidePreview() {
    _previewPosition = null;
    _previewOffset = null;
    _previewOverlay?.remove();
    _previewOverlay = null;
  }

  void _previewAt(Offset localPosition, double width) {
    if (_dur == Duration.zero) return;
    final usableWidth = (width - _trackHorizontalInset * 2).clamp(0.0, double.infinity);
    if (usableWidth == 0) return;
    final fraction = ((localPosition.dx - _trackHorizontalInset) / usableWidth).clamp(0.0, 1.0);
    _showPreview(_dur.inMilliseconds * fraction);
  }

  @override
  Widget build(BuildContext context) {
    final max = _dur.inMilliseconds.toDouble();
    final val = _pos.inMilliseconds.toDouble().clamp(0.0, max);
    final bufVal = _buf.inMilliseconds.toDouble().clamp(0.0, max);

    return LayoutBuilder(
      builder: (context, constraints) => MouseRegion(
        onHover: (event) => _previewAt(event.localPosition, constraints.maxWidth),
        onExit: (_) {
          if (!_dragging) _hidePreview();
        },
        child: SizedBox(
          height: 10,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 9),
              activeTrackColor: Theme.of(context).primaryColor,
              inactiveTrackColor: Colors.white24,
              secondaryActiveTrackColor: Colors.white38,
              thumbColor: Colors.white,
              trackShape: const RoundedRectSliderTrackShape(),
            ),
            child: Slider(
              value: val,
              min: 0.0,
              max: max,
              secondaryTrackValue: bufVal,
              onChangeStart: (value) {
                setState(() => _dragging = true);
                _showPreview(value);
              },
              onChanged: (value) {
                setState(() => _pos = Duration(milliseconds: value.toInt()));
                _showPreview(value);
              },
              onChangeEnd: (value) {
                setState(() => _dragging = false);
                _hidePreview();
                widget.player.seek(Duration(milliseconds: value.toInt()));
              },
            ),
          ),
        ),
      ),
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
  final Player player;

  const _DurationLabel({required this.player});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: player.stream.position,
      builder: (_, snap) => Text(
        '${_formatPlaybackDuration(snap.data ?? Duration.zero)} / '
        '${_formatPlaybackDuration(player.state.duration)}',
        style: const TextStyle(color: Colors.white70, fontSize: 12, fontFeatures: [FontFeature.tabularFigures()]),
      ),
    );
  }
}
