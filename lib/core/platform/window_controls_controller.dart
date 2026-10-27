// 【窗口交互】协调原生或应用绘制的窗口按钮。
// 使用所属视图的 WindowService，不持有播放资源。

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 控制系统或应用外壳持有的窗口按钮。
class WindowControlsController extends ChangeNotifier {
  WindowControlsController({required this.viewId});

  final int viewId;

  static const _nativeChannel = MethodChannel('mochi_player/window_controls');

  bool _isMiniPlayer = false;

  bool get isMiniPlayer => _isMiniPlayer;

  Future<void> configureTitlebar({required Size minimumSize}) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.macOS) return;
    await _nativeChannel.invokeMethod<void>('configureTitlebar', {
      'viewId': viewId,
      'minimumWidth': minimumSize.width,
      'minimumHeight': minimumSize.height,
    });
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
