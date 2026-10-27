// 【行为测试】验证控制全屏、迷你模式、置顶和尺寸恢复。
// 测试对象的职责边界：使用所属视图的窗口服务，不持有播放目标或数据库。

import 'dart:async';
import 'dart:ui' show Rect, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/platform/window_controls_controller.dart';
import 'package:mochi_player/core/platform/window_service.dart';
import 'package:mochi_player/features/playback/ui/controllers/player_window_mode_controller.dart';

class PendingFullscreenWindow extends WindowService {
  bool fullscreen = false;
  final requests = <bool>[];
  final confirmations = <Completer<void>>[];

  @override
  int get viewId => 1;
  @override
  void addListener(WindowEvents listener) {}
  @override
  void removeListener(WindowEvents listener) {}
  @override
  Future<bool> isFullScreen() async => fullscreen;
  @override
  Future<void> setFullScreen(bool value) async {
    requests.add(value);
    final confirmation = Completer<void>();
    confirmations.add(confirmation);
    await confirmation.future;
    fullscreen = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MiniWindow extends PendingFullscreenWindow {
  static const originalBounds = Rect.fromLTWH(80, 60, 1280, 720);
  Rect bounds = originalBounds;
  Size minimumSize = const Size(720, 405);
  bool onTop = false;
  int failBounds = 0;
  int failTop = 0;
  final restoredBounds = <Rect>[];

  @override
  Future<bool> isMaximized() async => false;
  @override
  Future<Rect> getBounds() async => bounds;
  @override
  Future<bool> isAlwaysOnTop() async => onTop;
  @override
  Future<void> setAlwaysOnTop(bool value) async {
    if (failTop > 0) {
      failTop--;
      throw StateError('native top operation failed');
    }
    onTop = value;
  }

  @override
  Future<void> setBounds(Rect value, {bool animate = false}) async {
    if (failBounds > 0) {
      failBounds--;
      throw StateError('native bounds operation failed');
    }
    bounds = value;
    restoredBounds.add(value);
  }

  @override
  Future<void> setMinimumSize(Size value) async => minimumSize = value;
}

Future<void> drain() => Future<void>.delayed(Duration.zero);

void main() {
  test('failed mini entry rolls back partial native changes and can be retried', () async {
    final windows = MiniWindow()..failTop = 1;
    final controls = WindowControlsController(viewId: 1);
    final modes = PlayerWindowModeController(
      windows: windows,
      windowControlsController: controls,
      regularMinimumWindowSize: const Size(720, 405),
    );
    modes.toggleMiniPlayer();
    await drain();
    expect(modes.isMiniPlayer, isFalse);
    expect(controls.isMiniPlayer, isFalse);
    expect(windows.bounds, MiniWindow.originalBounds);
    expect(windows.minimumSize, const Size(720, 405));
    expect(windows.onTop, isFalse);
    modes.toggleMiniPlayer();
    await drain();
    expect(modes.isMiniPlayer, isTrue);
    await modes.restoreWindow();
    modes.dispose();
    controls.dispose();
  });

  test('failed mini exit retains original bounds until a successful retry', () async {
    final windows = MiniWindow();
    final controls = WindowControlsController(viewId: 1);
    final modes = PlayerWindowModeController(
      windows: windows,
      windowControlsController: controls,
      regularMinimumWindowSize: const Size(720, 405),
    );
    modes.toggleMiniPlayer();
    await drain();
    windows.failBounds = 1;
    modes.toggleMiniPlayer();
    await drain();
    expect(modes.isMiniPlayer, isTrue);
    expect(modes.isMiniPlayerAlwaysOnTop, windows.onTop);
    modes.toggleMiniPlayer();
    await drain();
    expect(modes.isMiniPlayer, isFalse);
    expect(windows.bounds, MiniWindow.originalBounds);
    expect(controls.isMiniPlayer, isFalse);
    modes.dispose();
    controls.dispose();
  });

  test('failed entry and rollback retain the snapshot for the next entry', () async {
    final windows = MiniWindow()..failTop = 2;
    final controls = WindowControlsController(viewId: 1);
    final modes = PlayerWindowModeController(
      windows: windows,
      windowControlsController: controls,
      regularMinimumWindowSize: const Size(720, 405),
    );
    modes.toggleMiniPlayer();
    await drain();
    expect(modes.isMiniPlayer, isFalse);
    expect(windows.bounds, isNot(MiniWindow.originalBounds));
    modes.toggleMiniPlayer();
    await drain();
    expect(modes.isMiniPlayer, isTrue);
    expect(windows.restoredBounds, contains(MiniWindow.originalBounds));
    await modes.restoreWindow();
    expect(windows.bounds, MiniWindow.originalBounds);
    modes.dispose();
    controls.dispose();
  });

  test('failed top toggle preserves actual state and permits retry', () async {
    final windows = MiniWindow();
    final controls = WindowControlsController(viewId: 1);
    final modes = PlayerWindowModeController(
      windows: windows,
      windowControlsController: controls,
      regularMinimumWindowSize: const Size(720, 405),
    );
    modes.toggleMiniPlayer();
    await drain();
    windows.failTop = 1;
    modes.toggleMiniPlayerAlwaysOnTop();
    await drain();
    expect(modes.isMiniPlayerAlwaysOnTop, isTrue);
    modes.toggleMiniPlayerAlwaysOnTop();
    await drain();
    expect(modes.isMiniPlayerAlwaysOnTop, isFalse);
    expect(windows.onTop, isFalse);
    await modes.restoreWindow();
    modes.dispose();
    controls.dispose();
  });

  test('repeated fullscreen clicks do not issue another request before native confirmation', () async {
    final windows = PendingFullscreenWindow();
    final controls = WindowControlsController(viewId: 1);
    final modes = PlayerWindowModeController(
      windows: windows,
      windowControlsController: controls,
      regularMinimumWindowSize: const Size(720, 405),
    );
    await modes.initialize();
    modes.toggleFullScreen();
    await drain();
    modes.toggleFullScreen();
    expect(windows.requests, [true]);
    windows.confirmations.single.complete();
    await drain();
    modes.toggleFullScreen();
    await drain();
    expect(windows.requests, [true, false]);
    windows.confirmations.last.complete();
    await drain();
    expect(modes.isFullScreen, isFalse);
    modes.dispose();
    controls.dispose();
  });

  test('close restoration waits for entering fullscreen, then confirms leaving it', () async {
    final windows = PendingFullscreenWindow();
    final controls = WindowControlsController(viewId: 1);
    final modes = PlayerWindowModeController(
      windows: windows,
      windowControlsController: controls,
      regularMinimumWindowSize: const Size(720, 405),
    );
    await modes.initialize();
    modes.toggleFullScreen();
    await drain();
    var restored = false;
    final restoring = modes.restoreWindow().then((_) => restored = true);
    await drain();
    expect(windows.requests, [true]);
    expect(restored, isFalse);
    windows.confirmations.single.complete();
    await drain();
    expect(windows.requests, [true, false]);
    expect(restored, isFalse);
    windows.confirmations.last.complete();
    await restoring;
    expect(windows.fullscreen, isFalse);
    modes.dispose();
    controls.dispose();
  });

  test('failed confirmation restores the actual UI state and permits retry', () async {
    final windows = PendingFullscreenWindow();
    final controls = WindowControlsController(viewId: 1);
    final modes = PlayerWindowModeController(
      windows: windows,
      windowControlsController: controls,
      regularMinimumWindowSize: const Size(720, 405),
    );
    await modes.initialize();
    modes.toggleFullScreen();
    await drain();
    windows.confirmations.single.completeError(TimeoutException('native transition failed'));
    await drain();
    expect(modes.isFullScreen, isFalse);
    modes.toggleFullScreen();
    await drain();
    expect(windows.requests, [true, true]);
    windows.confirmations.last.complete();
    await drain();
    expect(modes.isFullScreen, isTrue);
    modes.dispose();
    controls.dispose();
  });

  test('a failed fullscreen exit retains restoration ownership for a retry', () async {
    final windows = PendingFullscreenWindow();
    final controls = WindowControlsController(viewId: 1);
    final modes = PlayerWindowModeController(
      windows: windows,
      windowControlsController: controls,
      regularMinimumWindowSize: const Size(720, 405),
    );
    await modes.initialize();
    modes.toggleFullScreen();
    await drain();
    windows.confirmations.single.complete();
    await drain();
    modes.toggleFullScreen();
    await drain();
    windows.confirmations.last.completeError(TimeoutException('exit failed'));
    await drain();
    expect(modes.isFullScreen, isTrue);
    modes.toggleFullScreen();
    await drain();
    expect(windows.requests, [true, false, false]);
    windows.confirmations.last.complete();
    await drain();
    expect(modes.isFullScreen, isFalse);
    modes.dispose();
    controls.dispose();
  });
}
