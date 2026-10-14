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
      // A hung Dart engine must not leave playback running indefinitely.
      // The Dart coordinator normally finishes within 26 seconds.
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
