import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  static var lifecycleChannel: FlutterMethodChannel?
  private var exitRequested = false

  override func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    guard let channel = Self.lifecycleChannel else {
      return .terminateNow
    }
    if !exitRequested {
      exitRequested = true
      channel.invokeMethod("requestExit", arguments: nil)
      // A hung main Dart engine must not leave playback running indefinitely.
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
