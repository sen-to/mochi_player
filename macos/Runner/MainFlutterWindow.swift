import Cocoa
import FlutterMacOS
import desktop_multi_window

class MainFlutterWindow: NSWindow {
  private static let windowButtonOffset = NSPoint(x: 12, y: -10)
  private var defaultWindowButtonOrigins: [NSWindow.ButtonType: NSPoint] = [:]
  private var windowButtonsConfigured = false
  private var nativeWindowButtonsVisible = true
  private var windowControlChannel: FlutterMethodChannel?
  private var windowObserverTokens: [NSObjectProtocol] = []
  private var windowButtonPositioningScheduled = false

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    FlutterMultiWindowPlugin.setOnWindowCreatedCallback { controller in
      RegisterGeneratedPlugins(registry: controller)
      Self.installChildWindowControls(for: controller)
    }

    let channel = FlutterMethodChannel(
      name: "mochi_player/window_controls",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(nil)
        return
      }

      switch call.method {
      case "positionNativeWindowButtons":
        self.windowButtonsConfigured = true
        if !self.positionNativeWindowButtons() {
          self.scheduleNativeWindowButtonPositioning()
        }
        result(nil)
      case "setNativeWindowButtonsVisible":
        guard let visible = call.arguments as? Bool else {
          result(
            FlutterError(
              code: "invalid_arguments",
              message: "Expected a Boolean visibility value.",
              details: nil
            )
          )
          return
        }
        if visible {
          self.showNativeWindowButtonsAfterPositioning()
        } else {
          self.nativeWindowButtonsVisible = false
          self.updateNativeWindowButtonVisibility()
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    windowControlChannel = channel

    super.awakeFromNib()
    observeWindowChromeChanges()
  }

  deinit {
    for token in windowObserverTokens {
      NotificationCenter.default.removeObserver(token)
    }
  }

  override func becomeKey() {
    super.becomeKey()
    guard windowButtonsConfigured else {
      return
    }

    if !positionNativeWindowButtons() {
      scheduleNativeWindowButtonPositioning()
    }
  }

  private func observeWindowChromeChanges() {
    let notifications: [Notification.Name] = [
      NSWindow.didResizeNotification,
      NSWindow.didEndLiveResizeNotification,
      NSWindow.didExitFullScreenNotification
    ]

    for notification in notifications {
      let token = NotificationCenter.default.addObserver(
        forName: notification,
        object: self,
        queue: .main
      ) { [weak self] _ in
        guard let self = self, self.windowButtonsConfigured else {
          return
        }
        if !self.positionNativeWindowButtons() {
          self.scheduleNativeWindowButtonPositioning()
        }
      }
      windowObserverTokens.append(token)
    }
  }

  private func scheduleNativeWindowButtonPositioning() {
    guard !windowButtonPositioningScheduled else {
      return
    }
    windowButtonPositioningScheduled = true
    DispatchQueue.main.async { [weak self] in
      guard let self = self else {
        return
      }
      self.windowButtonPositioningScheduled = false
      _ = self.positionNativeWindowButtons()
    }
  }

  private func showNativeWindowButtonsAfterPositioning() {
    nativeWindowButtonsVisible = false
    updateNativeWindowButtonVisibility()

    let positioned = positionNativeWindowButtons()
    nativeWindowButtonsVisible = true
    if positioned {
      updateNativeWindowButtonVisibility()
    } else {
      scheduleNativeWindowButtonPositioning()
    }
  }

  @discardableResult
  private func positionNativeWindowButtons() -> Bool {
    var positionedButtonCount = 0
    for buttonType in nativeWindowButtonTypes {
      guard let button = standardWindowButton(buttonType) else {
        continue
      }

      let currentOrigin = button.frame.origin
      if let defaultOrigin = defaultWindowButtonOrigins[buttonType] {
        let expectedOrigin = offsetWindowButtonOrigin(defaultOrigin)
        let appKitRepositionedButton =
          abs(currentOrigin.x - expectedOrigin.x) > 0.5 ||
          abs(currentOrigin.y - expectedOrigin.y) > 0.5
        if appKitRepositionedButton {
          defaultWindowButtonOrigins[buttonType] = currentOrigin
        }
      } else {
        defaultWindowButtonOrigins[buttonType] = currentOrigin
      }

      guard let defaultOrigin = defaultWindowButtonOrigins[buttonType] else {
        continue
      }
      button.setFrameOrigin(offsetWindowButtonOrigin(defaultOrigin))
      button.updateTrackingAreas()
      button.superview?.updateTrackingAreas()
      positionedButtonCount += 1
    }

    updateNativeWindowButtonVisibility()
    return positionedButtonCount == nativeWindowButtonTypes.count
  }

  private func offsetWindowButtonOrigin(_ origin: NSPoint) -> NSPoint {
    NSPoint(
      x: origin.x + Self.windowButtonOffset.x,
      y: origin.y + Self.windowButtonOffset.y
    )
  }

  private var nativeWindowButtonTypes: [NSWindow.ButtonType] {
    [
      .closeButton,
      .miniaturizeButton,
      .zoomButton
    ]
  }

  private func updateNativeWindowButtonVisibility() {
    for buttonType in nativeWindowButtonTypes {
      standardWindowButton(buttonType)?.isHidden = !nativeWindowButtonsVisible
    }
  }

  /// Child Flutter engines belong to their own NSWindow, so they cannot use
  /// the main window's channel handler. They only need to hide the standard
  /// controls while the compact player is active; their normal titlebar
  /// placement remains under AppKit's control.
  private static func installChildWindowControls(
    for controller: FlutterViewController
  ) {
    DispatchQueue.main.async {
      guard let window = controller.view.window else {
        return
      }

      let channel = FlutterMethodChannel(
        name: "mochi_player/window_controls",
        binaryMessenger: controller.engine.binaryMessenger
      )
      channel.setMethodCallHandler { [weak window] call, result in
        guard let window else {
          result(nil)
          return
        }

        switch call.method {
        case "setNativeWindowButtonsVisible":
          guard let visible = call.arguments as? Bool else {
            result(
              FlutterError(
                code: "invalid_arguments",
                message: "Expected a Boolean visibility value.",
                details: nil
              )
            )
            return
          }
          for buttonType in [
            NSWindow.ButtonType.closeButton,
            .miniaturizeButton,
            .zoomButton
          ] {
            window.standardWindowButton(buttonType)?.isHidden = !visible
          }
          result(nil)
        case "closePlayerWindow":
          result(nil)
          DispatchQueue.main.async {
            window.close()
          }
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
  }
}
