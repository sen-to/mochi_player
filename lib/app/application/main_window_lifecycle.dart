import 'dart:ui' show AppExitResponse;
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:mochi_player/app/application/application_exit_coordinator.dart';
import 'package:mochi_player/core/platform/window_service.dart';

/// Routes the native close button and platform exit requests to one coordinator.
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
