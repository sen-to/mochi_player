import 'dart:ui' show Rect, Size;

/// The only desktop-window API exposed to application and playback code.
abstract class WindowService {
  int get viewId;

  void addListener(WindowEvents listener);

  void removeListener(WindowEvents listener);

  Future<void> setPreventClose(bool prevent);

  Future<void> activate();

  Future<void> close();

  Future<void> startDragging();

  Future<String?> pickDirectory({String? initialDirectory});

  Future<String?> pickFile({required List<String> extensions, required String label});

  Future<bool> isMaximized();

  Future<void> maximize();

  Future<void> unmaximize();

  Future<Rect> getBounds();

  Future<void> setBounds(Rect bounds, {bool animate = false});

  Future<void> setMinimumSize(Size size);

  Future<bool> isAlwaysOnTop();

  Future<void> setAlwaysOnTop(bool value);

  Future<bool> isFullScreen();

  /// Completes when the native window confirms the requested state, or fails
  /// within a bounded wait. Callers must not treat sending a request as success.
  Future<void> setFullScreen(bool value);

  /// Ends the whole process after application-owned cleanup, including all windows. This must only be called by the main window.
  void exitApplication();
}

abstract mixin class WindowEvents {
  void onWindowClose() {}

  void onWindowEnterFullScreen() {}

  void onWindowLeaveFullScreen() {}
}

class WindowSetup {
  const WindowSetup({required this.size, required this.minimumSize});

  final Size size;
  final Size minimumSize;
}
