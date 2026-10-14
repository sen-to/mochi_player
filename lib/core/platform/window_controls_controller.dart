import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Controls window buttons that are owned by the operating system or app shell.
class WindowControlsController extends ChangeNotifier {
  WindowControlsController({required this.viewId});

  final int viewId;

  static const _nativeChannel = MethodChannel('mochi_player/window_controls');

  bool _isMiniPlayer = false;

  bool get isMiniPlayer => _isMiniPlayer;

  Future<void> configureTitlebar() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.macOS) return;
    await _nativeChannel.invokeMethod<void>('configureTitlebar', {'viewId': viewId});
  }

  Future<void> setMiniPlayerMode(bool enabled) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
      await _nativeChannel.invokeMethod<void>('setNativeWindowButtonsVisible', {'viewId': viewId, 'visible': !enabled});
    }
    if (_isMiniPlayer != enabled) {
      _isMiniPlayer = enabled;
      notifyListeners();
    }
  }
}
