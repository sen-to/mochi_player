import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mochi_player/core/platform/window_controls_controller.dart';
import 'package:window_manager/window_manager.dart';

/// Manages the desktop window modes used only by the playback experience.
///
/// Playback state stays outside this controller. It owns the transitions and
/// restoration data needed for fullscreen and mini-player window modes.
class PlayerWindowModeController extends ChangeNotifier with WindowListener {
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

  final WindowControlsController windowControlsController;
  final Size regularMinimumWindowSize;

  bool get isFullScreen => _isFullScreen;

  bool get isMiniPlayer => _isMiniPlayer;

  bool get isMiniPlayerAlwaysOnTop => _isMiniPlayerAlwaysOnTop;

  PlayerWindowModeController({required this.windowControlsController, required this.regularMinimumWindowSize}) {
    windowManager.addListener(this);
  }

  Future<void> initialize() => _ensureInitialFullScreenStateCaptured();

  void toggleFullScreen() {
    if (_isDisposed || _fullScreenTransition != null) return;

    _fullScreenTransition = _togglePlayerFullScreen().whenComplete(() {
      _fullScreenTransition = null;
    });
    unawaited(_fullScreenTransition);
  }

  void toggleMiniPlayer() {
    if (_isDisposed || _miniPlayerTransition != null) return;

    _miniPlayerTransition = (_isMiniPlayer ? _exitMiniPlayer() : _enterMiniPlayer()).whenComplete(
      () => _miniPlayerTransition = null,
    );
    unawaited(_miniPlayerTransition);
  }

  void toggleMiniPlayerAlwaysOnTop() {
    if (_isDisposed || !_isMiniPlayer || _miniAlwaysOnTopTransition != null) {
      return;
    }

    final nextValue = !_isMiniPlayerAlwaysOnTop;
    _miniAlwaysOnTopTransition = () async {
      await windowManager.setAlwaysOnTop(nextValue);
      if (_isDisposed) return;
      _isMiniPlayerAlwaysOnTop = nextValue;
      notifyListeners();
    }().whenComplete(() => _miniAlwaysOnTopTransition = null);
    unawaited(_miniAlwaysOnTopTransition);
  }

  Future<void> exitFullScreen() async {
    await _fullScreenTransition;
    await _exitPlayerFullScreen();
  }

  /// Restores the regular app window after the playback page is disposed.
  ///
  /// The page removes its listener before invoking this, so restoration does
  /// not try to rebuild a widget that is leaving the tree.
  Future<void> restoreWindow() async {
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
    await _fullScreenTransition;
    if (_isDisposed) return;

    if (_isFullScreen) {
      await _exitPlayerFullScreen();
      if (_isDisposed) return;
    }

    _windowWasMaximizedBeforeMiniPlayer = await windowManager.isMaximized();
    if (_windowWasMaximizedBeforeMiniPlayer) {
      await windowManager.unmaximize();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (_isDisposed) return;

    final currentBounds = await windowManager.getBounds();
    _windowBoundsBeforeMiniPlayer = currentBounds;
    _windowWasAlwaysOnTopBeforeMiniPlayer = await windowManager.isAlwaysOnTop();
    await windowControlsController.setMiniPlayerMode(true);

    final targetPosition = Offset(
      (currentBounds.right - _miniPlayerSize.width).clamp(0.0, double.infinity),
      (currentBounds.bottom - _miniPlayerSize.height).clamp(0.0, double.infinity),
    );
    await windowManager.setMinimumSize(_miniPlayerMinimumSize);
    await windowManager.setBounds(targetPosition & _miniPlayerSize, animate: true);
    await windowManager.setAlwaysOnTop(true);

    if (_isDisposed) return;
    _isMiniPlayer = true;
    _isMiniPlayerAlwaysOnTop = true;
    notifyListeners();
  }

  Future<void> _exitMiniPlayer({bool notify = true}) async {
    if (!_isMiniPlayer && _windowBoundsBeforeMiniPlayer == null) return;

    await _miniAlwaysOnTopTransition;
    final previousBounds = _windowBoundsBeforeMiniPlayer;
    _windowBoundsBeforeMiniPlayer = null;
    await windowManager.setAlwaysOnTop(_windowWasAlwaysOnTopBeforeMiniPlayer);
    if (previousBounds != null) {
      await windowManager.setBounds(previousBounds, animate: true);
    }
    await windowManager.setMinimumSize(regularMinimumWindowSize);
    if (_windowWasMaximizedBeforeMiniPlayer) {
      await windowManager.maximize();
    }

    _windowWasMaximizedBeforeMiniPlayer = false;
    _isMiniPlayer = false;
    _isMiniPlayerAlwaysOnTop = false;
    await windowControlsController.setMiniPlayerMode(false);
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

    final windowIsFullScreen = await windowManager.isFullScreen();
    if (_isDisposed) return;

    if (!windowIsFullScreen) {
      _playerUsedWindowFullScreen = true;
      await windowManager.setFullScreen(true);
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
    _playerUsedWindowFullScreen = false;

    if (shouldRestoreWindow) {
      await windowManager.setFullScreen(false);
    }
  }

  Future<void> _ensureInitialFullScreenStateCaptured() {
    return _initialWindowFullScreenCapture ??= () async {
      _windowWasFullScreenOnOpen = await windowManager.isFullScreen();
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
    windowManager.removeListener(this);
    super.dispose();
  }
}
