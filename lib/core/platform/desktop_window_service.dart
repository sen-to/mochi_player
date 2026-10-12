import 'dart:async';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/services.dart';
import 'package:mochi_player/core/platform/window_service.dart';
import 'package:window_manager/window_manager.dart';

/// Adapter for the current engine-per-window backend. window_manager operates
/// on the calling engine's window; remote control goes through WindowHandle.
class DesktopWindowService extends WindowService with WindowListener {
  final Set<WindowEvents> _listeners = {};
  static const _nativeControls = MethodChannel('mochi_player/window_controls');

  @override
  Future<WindowHandle> current() async => _DesktopWindowHandle(await WindowController.fromCurrentEngine());

  @override
  Future<WindowHandle> create(String arguments) async => _DesktopWindowHandle(
    await WindowController.create(WindowConfiguration(arguments: arguments, hiddenAtLaunch: true)),
  );

  @override
  Future<List<WindowHandle>> getAll() async => (await WindowController.getAll()).map(_DesktopWindowHandle.new).toList();

  @override
  Future<void> initialize() async {
    await windowManager.ensureInitialized();
    windowManager.addListener(this);
  }

  @override
  Future<void> configure(WindowSetup setup) async {
    await windowManager.waitUntilReadyToShow(
      WindowOptions(
        size: setup.size,
        minimumSize: setup.minimumSize,
        center: true,
        title: 'Mochi Player',
        backgroundColor: setup.backgroundColor,
        skipTaskbar: false,
        titleBarStyle: Platform.isWindows ? TitleBarStyle.normal : TitleBarStyle.hidden,
        windowButtonVisibility: Platform.isMacOS,
      ),
    );
    await activate();
  }

  @override
  void addListener(WindowEvents listener) => _listeners.add(listener);

  @override
  void removeListener(WindowEvents listener) => _listeners.remove(listener);

  @override
  void onWindowClose() {
    for (final listener in _listeners.toList()) {
      listener.onWindowClose();
    }
  }

  @override
  void onWindowEnterFullScreen() {
    for (final listener in _listeners.toList()) {
      listener.onWindowEnterFullScreen();
    }
  }

  @override
  void onWindowLeaveFullScreen() {
    for (final listener in _listeners.toList()) {
      listener.onWindowLeaveFullScreen();
    }
  }

  @override
  Future<void> setPreventClose(bool prevent) => windowManager.setPreventClose(prevent);

  @override
  Future<void> activate() async {
    await windowManager.show();
    await windowManager.focus();
  }

  @override
  Future<void> close() async {
    await setPreventClose(false);
    if (Platform.isMacOS) {
      await _nativeControls.invokeMethod<void>('closePlayerWindow');
    } else {
      await windowManager.close();
    }
  }

  @override
  void exitApplication() => exit(0);

  @override
  Future<void> startDragging() => windowManager.startDragging();

  @override
  Future<bool> isMaximized() => windowManager.isMaximized();

  @override
  Future<void> maximize() => windowManager.maximize();

  @override
  Future<void> unmaximize() => windowManager.unmaximize();

  @override
  Future<Rect> getBounds() => windowManager.getBounds();

  @override
  Future<void> setBounds(Rect bounds, {bool animate = false}) => windowManager.setBounds(bounds, animate: animate);

  @override
  Future<void> setMinimumSize(Size size) => windowManager.setMinimumSize(size);

  @override
  Future<bool> isAlwaysOnTop() => windowManager.isAlwaysOnTop();

  @override
  Future<void> setAlwaysOnTop(bool value) => windowManager.setAlwaysOnTop(value);

  @override
  Future<bool> isFullScreen() => windowManager.isFullScreen();

  @override
  Future<void> setFullScreen(bool value) => windowManager.setFullScreen(value);
}

class _DesktopWindowHandle implements WindowHandle {
  _DesktopWindowHandle(this._controller);

  final WindowController _controller;

  @override
  String get id => _controller.windowId;

  @override
  String get arguments => _controller.arguments;

  @override
  Future<T?> invoke<T>(String method, [Object? arguments, Duration? timeout]) =>
      _controller.invokeMethod<T>(method, arguments).timeout(timeout ?? const Duration(seconds: 3));

  @override
  Future<void> setHandler(Future<Object?> Function(MethodCall call) handler) =>
      _controller.setWindowMethodHandler(handler);
}
