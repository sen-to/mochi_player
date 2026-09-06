import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Controls window buttons that are owned by the operating system or app shell.
class WindowControlsController extends ChangeNotifier {
  static const _nativeChannel = MethodChannel('mochi_player/window_controls');

  bool _isMiniPlayer = false;

  bool get isMiniPlayer => _isMiniPlayer;

  Future<void> positionNativeWindowButtons() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.macOS) return;
    await _nativeChannel.invokeMethod<void>('positionNativeWindowButtons');
  }

  Future<void> setMiniPlayerMode(bool enabled) async {
    if (_isMiniPlayer != enabled) {
      _isMiniPlayer = enabled;
      notifyListeners();
    }
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }
    await _nativeChannel.invokeMethod<void>('setNativeWindowButtonsVisible', !enabled);
  }
}
