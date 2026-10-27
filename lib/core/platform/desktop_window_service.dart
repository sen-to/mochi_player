// 【平台适配】通过单引擎视图注册表创建和管理桌面视图。
// 每个视图获得独立窗口服务，窗口操作显式携带视图身份。

// 官方多窗口能力仍处于实验阶段，SDK 内部接口只允许在此适配器中使用。
// ignore_for_file: implementation_imports, invalid_use_of_internal_member
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/_window.dart' as official;
import 'package:flutter/widgets.dart';
import 'package:mochi_player/core/platform/window_service.dart';
import 'package:provider/provider.dart';

/// 一个引擎共用一个视图注册表，每个视图获得自己的 WindowService。
class DesktopWindowHost {
  official.WindowRegistry? _registry;
  final Map<_DesktopWindowService, official.WindowEntry> _entries = {};

  List<WindowService> get windows => List.unmodifiable(_entries.keys);

  WindowService create({required WindowSetup setup, required WidgetBuilder builder}) {
    final service = _DesktopWindowService._(this, setup);
    final entry = official.WindowEntry(
      controller: service._controller,
      builder: (context) {
        _registry = official.WindowRegistry.of(context);
        return Provider<WindowService>.value(
          value: service,
          child: Builder(builder: builder),
        );
      },
    );
    _entries[service] = entry;
    _registry?.register(entry);
    return service;
  }

  Widget buildRoot() => official.WindowManager(initialWindows: _entries.values.toList());

  Future<void> _close(_DesktopWindowService service) async {
    final entry = _entries.remove(service);
    if (entry == null) return;
    _registry!.unregister(entry);
    // 先从组件树移除视图，再使对应的 FlutterView 失效。
    await WidgetsBinding.instance.endOfFrame;
    service._controller.removeListener(service._stateChanged);
    service._controller.destroy();
    service._controller.dispose();
  }
}

class _DesktopWindowService extends WindowService with official.WindowControllerDelegate {
  _DesktopWindowService._(this._host, WindowSetup setup) {
    _controller = official.WindowController(
      title: 'Mochi Player',
      size: setup.size,
      constraints: BoxConstraints(minWidth: setup.minimumSize.width, minHeight: setup.minimumSize.height),
      delegate: this,
    );
    // 固定 SDK 的 Windows 宿主遗漏初始原生约束；创建后重新应用，使拖动缩放也遵守最小尺寸。
    if (Platform.isWindows) {
      _controller.setConstraints(
        BoxConstraints(minWidth: setup.minimumSize.width, minHeight: setup.minimumSize.height),
      );
    }
    _fullscreen = _controller.isFullscreen;
    _controller.addListener(_stateChanged);
  }

  final DesktopWindowHost _host;
  late final official.WindowController _controller;
  final Set<WindowEvents> _listeners = {};
  bool _preventClose = false;
  bool _fullscreen = false;
  Future<void>? _closing;
  static const _native = MethodChannel('mochi_player/window_controls');

  @override
  int get viewId => _controller.rootView.viewId;

  Future<T?> _invoke<T>(String method, [Map<String, Object?> arguments = const {}]) =>
      _native.invokeMethod<T>(method, {'viewId': viewId, ...arguments});

  void _stateChanged() {
    final next = _controller.isFullscreen;
    if (next == _fullscreen) return;
    _fullscreen = next;
    for (final listener in List.of(_listeners)) {
      if (next) {
        listener.onWindowEnterFullScreen();
      } else {
        listener.onWindowLeaveFullScreen();
      }
    }
  }

  @override
  void onWindowCloseRequested(official.WindowController controller) {
    if (_preventClose) {
      for (final listener in List.of(_listeners)) {
        listener.onWindowClose();
      }
    } else {
      close();
    }
  }

  @override
  void addListener(WindowEvents listener) => _listeners.add(listener);
  @override
  void removeListener(WindowEvents listener) => _listeners.remove(listener);
  @override
  Future<void> setPreventClose(bool prevent) async => _preventClose = prevent;
  @override
  Future<void> activate() async => _controller.activate();
  @override
  Future<void> close() => _closing ??= _host._close(this);
  @override
  Future<void> startDragging() => _invoke<void>('startDragging');
  @override
  Future<String?> pickDirectory({String? initialDirectory}) =>
      _invoke<String>('pickPath', {'directory': true, 'initialDirectory': initialDirectory});
  @override
  Future<String?> pickFile({required List<String> extensions, required String label}) =>
      _invoke<String>('pickPath', {'directory': false, 'extensions': extensions, 'label': label});
  @override
  Future<bool> isMaximized() async => _controller.isMaximized;
  @override
  Future<void> maximize() async => _controller.setMaximized(true);
  @override
  Future<void> unmaximize() async => _controller.setMaximized(false);
  @override
  Future<Rect> getBounds() async {
    final bounds = (await _invoke<List<Object?>>('getBounds'))!;
    return Rect.fromLTWH(
      (bounds[0] as num).toDouble(),
      (bounds[1] as num).toDouble(),
      (bounds[2] as num).toDouble(),
      (bounds[3] as num).toDouble(),
    );
  }

  @override
  Future<void> setBounds(Rect bounds, {bool animate = false}) => _invoke<void>('setBounds', {
    'x': bounds.left,
    'y': bounds.top,
    'width': bounds.width,
    'height': bounds.height,
    'animate': animate,
  });
  @override
  Future<void> setMinimumSize(Size size) async =>
      _controller.setConstraints(BoxConstraints(minWidth: size.width, minHeight: size.height));
  @override
  Future<bool> isAlwaysOnTop() async => (await _invoke<bool>('isAlwaysOnTop'))!;
  @override
  Future<void> setAlwaysOnTop(bool value) => _invoke<void>('setAlwaysOnTop', {'enabled': value});
  @override
  Future<bool> isFullScreen() async => _controller.isFullscreen;
  @override
  Future<void> setFullScreen(bool value) async {
    if (_controller.isFullscreen != value) _controller.setFullscreen(value);
    if (Platform.isMacOS) {
      // 样式标志可能早于 AppKit 动画完成发生变化；收到完成通知后才允许下一次请求。
      await _invoke<void>('waitForFullscreen', {'enabled': value});
      _stateChanged();
      return;
    }
    // 控制器确认原生状态前，窗口转换始终保持串行。
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (_controller.isFullscreen != value) {
      if (_closing != null) throw StateError('Window closed during fullscreen transition.');
      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException('Native window did not confirm fullscreen=$value.');
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    _stateChanged();
  }

  @override
  void exitApplication() => exit(0);
}
