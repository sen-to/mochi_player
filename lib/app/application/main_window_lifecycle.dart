// 【应用生命周期】将主窗口关闭及系统退出请求交给退出协调器。
// 不在窗口回调中直接销毁共享数据库或播放引擎。

import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:mochi_player/app/application/application_exit_coordinator.dart';
import 'package:mochi_player/core/platform/window_service.dart';

/// 将原生关闭按钮和平台退出请求交给同一个协调器。
class MainWindowLifecycle with WindowEvents {
  MainWindowLifecycle(this.windows, this.coordinator);

  final WindowService windows;
  final ApplicationExitCoordinator coordinator;
  static const _channel = MethodChannel('mochi_player/application_lifecycle');
  late final AppLifecycleListener _appLifecycle;

  Future<void> install() async {
    await windows.setPreventClose(true);
    windows.addListener(this);
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'requestExit') throw MissingPluginException('Unsupported application lifecycle method.');
      unawaited(coordinator.requestExit());
      return null;
    });
    _appLifecycle = AppLifecycleListener(
      onExitRequested: () async {
        await coordinator.requestExit();
        return AppExitResponse.cancel;
      },
    );
  }

  @override
  void onWindowClose() => unawaited(coordinator.requestExit());

  void dispose() {
    windows.removeListener(this);
    _appLifecycle.dispose();
    _channel.setMethodCallHandler(null);
  }
}
