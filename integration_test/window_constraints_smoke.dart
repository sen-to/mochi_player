// Run: fvm flutter run -d windows --release -t integration_test/window_constraints_smoke.dart
// Or: fvm flutter run -d macos --release -t integration_test/window_constraints_smoke.dart
// Queries native resize limits, including macOS titlebar configuration.
import 'dart:async';
import 'dart:ffi' hide Size;
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:mochi_player/app/bootstrap/mochi_widgets_binding.dart';
import 'package:mochi_player/core/platform/desktop_window_service.dart';
import 'package:mochi_player/core/platform/window_service.dart';
import 'package:mochi_player/core/platform/window_controls_controller.dart';

final _user32 = DynamicLibrary.open('user32.dll');
final _findWindow = _user32
    .lookupFunction<
      IntPtr Function(IntPtr, IntPtr, Pointer<Utf16>, Pointer<Utf16>),
      int Function(int, int, Pointer<Utf16>, Pointer<Utf16>)
    >('FindWindowExW');
final _windowProcess = _user32
    .lookupFunction<Uint32 Function(IntPtr, Pointer<Uint32>), int Function(int, Pointer<Uint32>)>(
      'GetWindowThreadProcessId',
    );
final _sendMessage = _user32
    .lookupFunction<
      IntPtr Function(IntPtr, Uint32, IntPtr, Pointer<Int32>),
      int Function(int, int, int, Pointer<Int32>)
    >('SendMessageW');
final _getClientRect = _user32
    .lookupFunction<Int32 Function(IntPtr, Pointer<Int32>), int Function(int, Pointer<Int32>)>('GetClientRect');
final _getWindowRect = _user32
    .lookupFunction<Int32 Function(IntPtr, Pointer<Int32>), int Function(int, Pointer<Int32>)>('GetWindowRect');
final _getDpi = _user32.lookupFunction<Uint32 Function(IntPtr), int Function(int)>('GetDpiForWindow');

Set<int> windowHandles() {
  final className = 'FLUTTER_HOST_WINDOW'.toNativeUtf16();
  final process = calloc<Uint32>();
  try {
    final handles = <int>{};
    var handle = 0;
    while ((handle = _findWindow(0, handle, className, nullptr)) != 0) {
      _windowProcess(handle, process);
      if (process.value == pid) handles.add(handle);
    }
    return handles;
  } finally {
    calloc.free(className);
    calloc.free(process);
  }
}

void checkWindowsMinimum(int handle, Size expected) {
  final info = calloc<Int32>(10);
  final client = calloc<Int32>(4);
  final window = calloc<Int32>(4);
  try {
    if (_getClientRect(handle, client) == 0 || _getWindowRect(handle, window) == 0) {
      throw StateError('Could not read native window bounds.');
    }
    final scale = _getDpi(handle) / 96;
    if (scale <= 0) throw StateError('Could not read native window DPI.');
    _sendMessage(handle, 0x0024, 0, info); // WM_GETMINMAXINFO
    final width = (info[6] - (window[2] - window[0] - client[2] + client[0])) / scale;
    final height = (info[7] - (window[3] - window[1] - client[3] + client[1])) / scale;
    if ((width - expected.width).abs() > 1 / scale || (height - expected.height).abs() > 1 / scale) {
      throw StateError('Expected native minimum $expected, got $width × $height.');
    }
    debugPrint('WINDOW CONSTRAINTS PASS: ${expected.width} × ${expected.height}');
  } finally {
    calloc.free(info);
    calloc.free(client);
    calloc.free(window);
  }
}

Future<void> checkMinimum(WindowService service, int? handle, Size expected) async {
  if (Platform.isWindows) {
    checkWindowsMinimum(handle!, expected);
    return;
  }
  const channel = MethodChannel('mochi_player/window_controls');
  final values = (await channel.invokeListMethod<num>('getMinimumSize', {'viewId': service.viewId}))!;
  if (values.length != 2) throw StateError('Expected the native minimum content size.');
  for (var index = 0; index < values.length; index++) {
    final target = index.isEven ? expected.width : expected.height;
    if ((values[index] - target).abs() > 1) {
      throw StateError('Expected AppKit minimum ${expected.width} × ${expected.height}, got $values.');
    }
  }
  debugPrint('WINDOW CONSTRAINTS PASS: AppKit ${expected.width} × ${expected.height}');
}

Future<void> configureTitlebar(WindowService service, Size minimum) async {
  final controls = WindowControlsController(viewId: service.viewId);
  try {
    await controls.configureTitlebar(minimumSize: minimum);
  } finally {
    controls.dispose();
  }
}

void main() {
  if (!Platform.isWindows && !Platform.isMacOS) {
    throw UnsupportedError('Window constraints smoke requires Windows or macOS.');
  }
  MochiWidgetsBinding();
  Timer(const Duration(seconds: 30), () {
    debugPrint('WINDOW CONSTRAINTS SMOKE FAILED: timed out');
    exit(1);
  });
  final host = DesktopWindowHost();
  WindowService create(Size minimum) => host.create(
    setup: WindowSetup(size: const Size(1200, 800), minimumSize: minimum),
    builder: (_) => const Directionality(textDirection: TextDirection.ltr, child: SizedBox.expand()),
  );
  final mainWindow = create(const Size(900, 600));
  runWidget(host.buildRoot());
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => unawaited(() async {
      try {
        // Finish the native first-frame callback before creating another view.
        await Future<void>.delayed(const Duration(milliseconds: 300));
        final mainHandle = Platform.isWindows ? windowHandles().single : null;
        await configureTitlebar(mainWindow, const Size(900, 600));
        await checkMinimum(mainWindow, mainHandle, const Size(900, 600));
        final player = create(const Size(720, 405));
        await WidgetsBinding.instance.endOfFrame;
        final playerHandle = Platform.isWindows ? windowHandles().difference({mainHandle!}).single : null;
        await configureTitlebar(player, const Size(720, 405));
        await checkMinimum(player, playerHandle, const Size(720, 405));
        await player.setMinimumSize(const Size(420, 260));
        await checkMinimum(player, playerHandle, const Size(420, 260));
        await checkMinimum(mainWindow, mainHandle, const Size(900, 600));
        await player.setMinimumSize(const Size(720, 405));
        await checkMinimum(player, playerHandle, const Size(720, 405));
        await player.close();
        final reopened = create(const Size(720, 405));
        await WidgetsBinding.instance.endOfFrame;
        final reopenedHandle = Platform.isWindows ? windowHandles().difference({mainHandle!}).single : null;
        await configureTitlebar(reopened, const Size(720, 405));
        await checkMinimum(reopened, reopenedHandle, const Size(720, 405));
        await reopened.close();
        await checkMinimum(mainWindow, mainHandle, const Size(900, 600));
        debugPrint('WINDOW CONSTRAINTS SMOKE COMPLETE');
        mainWindow.exitApplication();
      } catch (error, stack) {
        debugPrint('$error\n$stack');
        exit(1);
      }
    }()),
  );
}
