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

  final WindowControlsController windowControlsController;
  final Size regularMinimumWindowSize;

  bool get isFullScreen => _isFullScreen;

  bool get isMiniPlayer => _isMiniPlayer;

  bool get isMiniPlayerAlwaysOnTop => _isMiniPlayerAlwaysOnTop;

  PlayerWindowModeController({required this.windowControlsController, required this.regularMinimumWindowSize}) {
    WindowService.instance.addListener(this);
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
      await WindowService.instance.setAlwaysOnTop(nextValue);
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
    await _fullScreenTransition;
    if (_isDisposed) return;

    if (_isFullScreen) {
      await _exitPlayerFullScreen();
      if (_isDisposed) return;
    }

    _windowWasMaximizedBeforeMiniPlayer = await WindowService.instance.isMaximized();
    if (_windowWasMaximizedBeforeMiniPlayer) {
      await WindowService.instance.unmaximize();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (_isDisposed) return;

    final currentBounds = await WindowService.instance.getBounds();
    _windowBoundsBeforeMiniPlayer = currentBounds;
    _windowWasAlwaysOnTopBeforeMiniPlayer = await WindowService.instance.isAlwaysOnTop();
    await windowControlsController.setMiniPlayerMode(true);

    final targetPosition = Offset(
      (currentBounds.right - _miniPlayerSize.width).clamp(0.0, double.infinity),
      (currentBounds.bottom - _miniPlayerSize.height).clamp(0.0, double.infinity),
    );
    await WindowService.instance.setMinimumSize(_miniPlayerMinimumSize);
    await WindowService.instance.setBounds(targetPosition & _miniPlayerSize, animate: true);
    await WindowService.instance.setAlwaysOnTop(true);

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
    await WindowService.instance.setAlwaysOnTop(_windowWasAlwaysOnTopBeforeMiniPlayer);
    if (previousBounds != null) {
      await WindowService.instance.setBounds(previousBounds, animate: true);
    }
    await WindowService.instance.setMinimumSize(regularMinimumWindowSize);
    if (_windowWasMaximizedBeforeMiniPlayer) {
      await WindowService.instance.maximize();
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

    final windowIsFullScreen = await WindowService.instance.isFullScreen();
    if (_isDisposed) return;

    if (!windowIsFullScreen) {
      _playerUsedWindowFullScreen = true;
      await WindowService.instance.setFullScreen(true);
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
      await WindowService.instance.setFullScreen(false);
    }
  }

  Future<void> _ensureInitialFullScreenStateCaptured() {
    return _initialWindowFullScreenCapture ??= () async {
      _windowWasFullScreenOnOpen = await WindowService.instance.isFullScreen();
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
    WindowService.instance.removeListener(this);
    super.dispose();
  }
}
