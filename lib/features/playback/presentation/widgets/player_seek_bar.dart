import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/playback/application/playback_engine.dart';
import 'package:mochi_player/features/playback/presentation/widgets/player_overlay.dart';

/// Owns progress subscriptions, seek dragging and the timestamp overlay.
class PlayerSeekBar extends StatefulWidget {
  final PlaybackEngine engine;

  const PlayerSeekBar({super.key, required this.engine});

  @override
  State<PlayerSeekBar> createState() => _PlayerSeekBarState();
}

class _PlayerSeekBarState extends State<PlayerSeekBar> {
  static const double _trackHorizontalInset = AppSpacing.md;
  static const double _previewVerticalOffset = 34;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _buffered = Duration.zero;
  bool _dragging = false;
  Duration? _previewPosition;
  Offset? _previewOffset;
  OverlayEntry? _previewOverlay;
  late List<StreamSubscription<dynamic>> _subscriptions;

  @override
  void initState() {
    super.initState();
    _bindEngine();
  }

  @override
  void didUpdateWidget(covariant PlayerSeekBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.engine == widget.engine) return;
    _hidePreview();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _dragging = false;
    _bindEngine();
  }

  void _bindEngine() {
    _position = widget.engine.state.position;
    _duration = widget.engine.state.duration;
    _buffered = widget.engine.state.buffer;
    _subscriptions = [
      widget.engine.stream.position.listen((p) {
        if (!_dragging && mounted) setState(() => _position = p);
      }),
      widget.engine.stream.duration.listen((d) {
        if (mounted) setState(() => _duration = d);
      }),
      widget.engine.stream.buffer.listen((b) {
        if (mounted) setState(() => _buffered = b);
      }),
    ];
  }

  @override
  void dispose() {
    _hidePreview();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }

  void _showPreview(double value) {
    final renderBox = context.findRenderObject();
    if (renderBox is! RenderBox || !renderBox.hasSize) return;

    final usableWidth = (renderBox.size.width - _trackHorizontalInset * 2).clamp(0.0, double.infinity);
    final fraction = _duration.inMilliseconds == 0 ? 0.0 : (value / _duration.inMilliseconds).clamp(0.0, 1.0);
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
            child: _SeekTimePreview(position: _previewPosition ?? Duration.zero),
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
    _previewOverlay?.dispose();
    _previewOverlay = null;
  }

  void _previewAt(Offset localPosition, double width) {
    if (_duration == Duration.zero) return;
    final usableWidth = (width - _trackHorizontalInset * 2).clamp(0.0, double.infinity);
    if (usableWidth == 0) return;
    final fraction = ((localPosition.dx - _trackHorizontalInset) / usableWidth).clamp(0.0, 1.0);
    _showPreview(_duration.inMilliseconds * fraction);
  }

  @override
  Widget build(BuildContext context) {
    final max = _duration.inMilliseconds.toDouble();
    final val = _position.inMilliseconds.toDouble().clamp(0.0, max);
    final bufVal = _buffered.inMilliseconds.toDouble().clamp(0.0, max);

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
                setState(() => _position = Duration(milliseconds: value.toInt()));
                _showPreview(value);
              },
              onChangeEnd: (value) {
                setState(() => _dragging = false);
                _hidePreview();
                widget.engine.seek(Duration(milliseconds: value.toInt()));
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Glass timestamp shown above the seek bar for a hovered or dragged position.
class _SeekTimePreview extends StatelessWidget {
  final Duration position;

  const _SeekTimePreview({required this.position});

  @override
  Widget build(BuildContext context) {
    return AppGlassSurface(
      borderRadius: const BorderRadius.all(Radius.circular(AppRadii.control)),
      color: PlayerOverlayGlass.background,
      borderColor: PlayerOverlayGlass.border,
      blur: PlayerOverlayGlass.blur,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: Text(
        _formatDuration(position),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.none,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return duration.inHours > 0 ? '${duration.inHours}:$minutes:$seconds' : '$minutes:$seconds';
  }
}
