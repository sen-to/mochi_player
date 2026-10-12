import 'package:flutter/services.dart';

/// The only desktop-window API exposed to application and playback code.
abstract class WindowService {
  static late WindowService instance;

  Future<WindowHandle> current();

  Future<WindowHandle> create(String arguments);

  Future<List<WindowHandle>> getAll();

  Future<void> initialize();

  Future<void> configure(WindowSetup setup);

  void addListener(WindowEvents listener);

  void removeListener(WindowEvents listener);

  Future<void> setPreventClose(bool prevent);

  Future<void> activate();

  Future<void> close();

  Future<void> startDragging();

  Future<bool> isMaximized();

  Future<void> maximize();

  Future<void> unmaximize();

  Future<Rect> getBounds();

  Future<void> setBounds(Rect bounds, {bool animate = false});

  Future<void> setMinimumSize(Size size);

  Future<bool> isAlwaysOnTop();

  Future<void> setAlwaysOnTop(bool value);

  Future<bool> isFullScreen();

  Future<void> setFullScreen(bool value);

  /// Ends the whole process after application-owned cleanup, including any
  /// unresponsive child engine. This must only be called by the main window.
  void exitApplication();
}

abstract interface class WindowHandle {
  String get id;

  String get arguments;

  Future<T?> invoke<T>(String method, [Object? arguments, Duration? timeout]);

  Future<void> setHandler(Future<Object?> Function(MethodCall call) handler);
}

abstract mixin class WindowEvents {
  void onWindowClose() {}

  void onWindowEnterFullScreen() {}

  void onWindowLeaveFullScreen() {}
}

class WindowSetup {
  const WindowSetup({required this.size, required this.minimumSize, required this.backgroundColor});

  final Size size;
  final Size minimumSize;
  final Color backgroundColor;
}
