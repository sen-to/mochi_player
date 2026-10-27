// 【应用宿主】创建共享 Flutter 引擎、注册插件并接管系统退出请求。
// 引擎由应用持有，退出先交给 Dart 排空播放与持久化，超时才强制结束。

import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private var engine: FlutterEngine?
  private var controls: NativeWindowControls?
  private var lifecycleChannel: FlutterMethodChannel?
  private var exitRequested = false

  override func applicationDidFinishLaunching(_ notification: Notification) {
    let engine = FlutterEngine(name: "Mochi Player", project: nil)
    self.engine = engine
    lifecycleChannel = FlutterMethodChannel(
      name: "mochi_player/application_lifecycle", binaryMessenger: engine.binaryMessenger)
    controls = NativeWindowControls(engine: engine)
    RegisterGeneratedPlugins(registry: engine)
    engine.run(withEntrypoint: nil)
    super.applicationDidFinishLaunching(notification)
  }

  override func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    guard let channel = lifecycleChannel else {
      return .terminateNow
    }
    if !exitRequested {
      exitRequested = true
      channel.invokeMethod("requestExit", arguments: nil)
      // Dart 引擎失去响应时，也不能让播放无限持续。
      // Dart 退出协调器正常情况下会在 26 秒内完成。
      DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
        exit(0)
      }
    }
    return .terminateCancel
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
