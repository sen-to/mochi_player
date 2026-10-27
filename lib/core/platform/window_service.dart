// 【平台契约】定义所属视图的尺寸、位置、全屏与原生窗口操作。
// 界面使用此边界，平台桥实现留在桌面适配中。

import 'dart:ui' show Rect, Size;

/// 应用与播放代码可使用的统一桌面窗口接口。
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

  /// 原生窗口确认目标状态后才完成，或在有限等待后失败；发送请求不能当作操作成功。
  Future<void> setFullScreen(bool value);

  /// 应用资源收尾后结束整个进程及全部窗口；只能由主窗口调用。
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
