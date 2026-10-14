import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mochi_player/core/platform/window_controls_controller.dart';
import 'package:mochi_player/core/platform/window_service.dart';

/// Manages the desktop window modes used only by the playback experience.
///
/// Playback state stays outside this controller. It owns the transitions and
/// restoration data needed for fullscreen and mini-player window modes.
class PlayerWindowModeController extends ChangeNotifier with WindowEvents {
  static const Size _miniPlayerSize = Size(480, 300);
  static const Size _miniPlayerMinimumSize = Size(420, 260);

  bool _isFullScreen = false;
  bool _isMiniPlayer = false;
  bool _isMiniPlayerAlwaysOnTop = false;
  bool _windowWasFullScreenOnOpen = false;
  bool _playerUsedWindowFullScreen = false;
  bool _windowWasMaximizedBeforeMiniPlayer = false;
  bool _windowWasAlwaysOnTopBeforeMiniPlayer = false;
  bool _isDisposed = false;

  Rect? _windowBoundsBeforeMiniPlayer;
  Future<void>? _initialWindowFullScreenCapture;
  Future<void>? _fullScreenTransition;
  Future<void>? _miniPlayerTransition;
  Future<void>? _miniAlwaysOnTopTransition;
  Future<void>? _restoration;

  final WindowService windows;
  final WindowControlsController windowControlsController;
  final Size regularMinimumWindowSize;

  bool get isFullScreen => _isFullScreen;

  bool get isMiniPlayer => _isMiniPlayer;

  bool get isMiniPlayerAlwaysOnTop => _isMiniPlayerAlwaysOnTop;

  PlayerWindowModeController({
    required this.windows,
    required this.windowControlsController,
    required this.regularMinimumWindowSize,
  }) {
    windows.addListener(this);
  }

  Future<void> initialize() => _ensureInitialFullScreenStateCaptured();

  void toggleFullScreen() {
    if (_isDisposed || _fullScreenTransition != null) return;

    _fullScreenTransition = _togglePlayerFullScreen().catchError(_handleFullScreenFailure).whenComplete(() {
      _fullScreenTransition = null;
    });
    unawaited(_fullScreenTransition);
  }

  void toggleMiniPlayer() {
    if (_isDisposed || _miniPlayerTransition != null) return;

    _miniPlayerTransition = (_isMiniPlayer ? _exitMiniPlayer() : _enterMiniPlayer())
        .catchError(_handleMiniPlayerFailure)
        .whenComplete(() => _miniPlayerTransition = null);
    unawaited(_miniPlayerTransition);
  }

  void toggleMiniPlayerAlwaysOnTop() {
    if (_isDisposed || !_isMiniPlayer || _miniAlwaysOnTopTransition != null) {
      return;
    }

    final nextValue = !_isMiniPlayerAlwaysOnTop;
    _miniAlwaysOnTopTransition = Future<void>.sync(() async {
      await windows.setAlwaysOnTop(nextValue);
      if (_isDisposed) return;
      _isMiniPlayerAlwaysOnTop = nextValue;
      notifyListeners();
    }).catchError(_handleAlwaysOnTopFailure).whenComplete(() => _miniAlwaysOnTopTransition = null);
    unawaited(_miniAlwaysOnTopTransition);
  }

  Future<void> _handleMiniPlayerFailure(Object error) async {
    debugPrint('播放器小窗切换失败: $error');
    // A failed entry may already have changed bounds, constraints or buttons.
    // Roll back partial changes; keep the snapshot if rollback also fails.
    if (_isMiniPlayer) {
      await _handleAlwaysOnTopFailure(error);
    } else if (_windowBoundsBeforeMiniPlayer != null) {
      try {
        await _exitMiniPlayer();
      } catch (restoreError) {
        debugPrint('播放器小窗恢复失败: $restoreError');
      }
    }
  }

  Future<void> _handleAlwaysOnTopFailure(Object error) async {
    debugPrint('播放器置顶切换失败: $error');
    if (_isDisposed) return;
    try {
      final actual = await windows.isAlwaysOnTop();
      if (_isDisposed) return;
      _isMiniPlayerAlwaysOnTop = actual;
      notifyListeners();
    } catch (stateError) {
      debugPrint('读取播放器置顶状态失败: $stateError');
    }
  }

  Future<void> exitFullScreen() async {
    await _fullScreenTransition;
    try {
      await _exitPlayerFullScreen();
    } catch (error) {
      await _handleFullScreenFailure(error);
    }
  }

  Future<void> _handleFullScreenFailure(Object error) async {
    debugPrint('播放器全屏切换失败: $error');
    if (_isDisposed) return;
    try {
      _isFullScreen = await windows.isFullScreen();
    } catch (_) {
      // A bounded shutdown may already have retired the native view.
      return;
    }
    if (!_isDisposed) notifyListeners();
  }

  /// Restores the regular app window after the playback page is disposed.
  ///
  /// The page removes its listener before invoking this, so restoration does
  /// not try to rebuild a widget that is leaving the tree.
  Future<void> restoreWindow() => _restoration ??= _restoreWindow();

  Future<void> _restoreWindow() async {
    await _miniPlayerTransition;
    await _exitMiniPlayer(notify: false);
    await _fullScreenTransition;
    await _exitPlayerFullScreen(notify: false);
  }

  Future<void> _togglePlayerFullScreen() async {
    if (_isMiniPlayer) {
      await _exitMiniPlayer();
      if (_isDisposed) return;
    }

    if (_isFullScreen) {
      await _exitPlayerFullScreen();
    } else {
      await _enterPlayerFullScreen();
    }
  }

  Future<void> _enterMiniPlayer() async {
    // Finish a previously failed rollback before capturing another snapshot.
    if (_windowBoundsBeforeMiniPlayer != null) await _exitMiniPlayer();
    await _fullScreenTransition;
    if (_isDisposed) return;

    if (_isFullScreen) {
      await _exitPlayerFullScreen();
      if (_isDisposed) return;
    }

    _windowWasMaximizedBeforeMiniPlayer = await windows.isMaximized();
    if (_windowWasMaximizedBeforeMiniPlayer) {
      await windows.unmaximize();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (_isDisposed) return;

    final currentBounds = await windows.getBounds();
    _windowWasAlwaysOnTopBeforeMiniPlayer = await windows.isAlwaysOnTop();
    _windowBoundsBeforeMiniPlayer = currentBounds;
    await windowControlsController.setMiniPlayerMode(true);

    final targetPosition = Offset(
      (currentBounds.right - _miniPlayerSize.width).clamp(0.0, double.infinity),
      (currentBounds.bottom - _miniPlayerSize.height).clamp(0.0, double.infinity),
    );
    await windows.setMinimumSize(_miniPlayerMinimumSize);
    await windows.setBounds(targetPosition & _miniPlayerSize, animate: true);
    await windows.setAlwaysOnTop(true);

    if (_isDisposed) return;
    _isMiniPlayer = true;
    _isMiniPlayerAlwaysOnTop = true;
    notifyListeners();
  }

  Future<void> _exitMiniPlayer({bool notify = true}) async {
    if (!_isMiniPlayer && _windowBoundsBeforeMiniPlayer == null) return;

    await _miniAlwaysOnTopTransition;
    final previousBounds = _windowBoundsBeforeMiniPlayer;
    await windows.setAlwaysOnTop(_windowWasAlwaysOnTopBeforeMiniPlayer);
    if (previousBounds != null) {
      await windows.setBounds(previousBounds, animate: true);
    }
    await windows.setMinimumSize(regularMinimumWindowSize);
    if (_windowWasMaximizedBeforeMiniPlayer) {
      await windows.maximize();
    }

    await windowControlsController.setMiniPlayerMode(false);
    _windowBoundsBeforeMiniPlayer = null;
    _windowWasMaximizedBeforeMiniPlayer = false;
    _isMiniPlayer = false;
    _isMiniPlayerAlwaysOnTop = false;
    if (notify && !_isDisposed) notifyListeners();
  }

  Future<void> _enterPlayerFullScreen() async {
    if (_isDisposed) return;

    if (!_isFullScreen) {
      _isFullScreen = true;
      notifyListeners();
    }

    await _ensureInitialFullScreenStateCaptured();
    if (_isDisposed) return;

    final windowIsFullScreen = await windows.isFullScreen();
    if (_isDisposed) return;

    if (!windowIsFullScreen) {
      _playerUsedWindowFullScreen = true;
      await windows.setFullScreen(true);
    } else {
      _playerUsedWindowFullScreen = false;
    }
  }

  Future<void> _exitPlayerFullScreen({bool notify = true}) async {
    final stateChanged = _isFullScreen;
    _isFullScreen = false;
    if (stateChanged && notify && !_isDisposed) notifyListeners();

    await _ensureInitialFullScreenStateCaptured();
    final shouldRestoreWindow = _playerUsedWindowFullScreen && !_windowWasFullScreenOnOpen;
    if (shouldRestoreWindow) {
      await windows.setFullScreen(false);
    }
    _playerUsedWindowFullScreen = false;
  }

  Future<void> _ensureInitialFullScreenStateCaptured() {
    return _initialWindowFullScreenCapture ??= () async {
      _windowWasFullScreenOnOpen = await windows.isFullScreen();
    }();
  }

  @override
  void onWindowEnterFullScreen() {
    // Native fullscreen entered outside the player remains an app window mode,
    // rather than being treated as player fullscreen.
  }

  @override
  void onWindowLeaveFullScreen() {
    if (_isDisposed || !_isFullScreen || !_playerUsedWindowFullScreen) return;
    _isFullScreen = false;
    _playerUsedWindowFullScreen = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    windows.removeListener(this);
    super.dispose();
  }
}
