// 【原生窗口适配】补充标题栏、文件选择、全屏等待与窗口几何操作。
// 按 Flutter 视图 ID 定位窗口；观察者及待完成请求由此适配器持有和释放。

import Cocoa
import FlutterMacOS
import UniformTypeIdentifiers

/// 补充实验性 Dart 窗口 API 尚未提供的原生操作。
/// 每次请求都按 Flutter 视图 ID 定位窗口，不依赖当前焦点窗口。
final class NativeWindowControls {
  private let channel: FlutterMethodChannel
  private var observers: [NSObjectProtocol] = []
  private var transitioning: Set<Int64> = []
  private var fullscreenRequests: [UUID: FullscreenRequest] = [:]

  private struct FullscreenRequest {
    let viewId: Int64
    let enabled: Bool
    let result: FlutterResult
  }

  init(engine: FlutterEngine) {
    channel = FlutterMethodChannel(
      name: "mochi_player/window_controls", binaryMessenger: engine.binaryMessenger)
    observeFullscreen(engine: engine)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      guard let args = call.arguments as? [String: Any],
            let viewId = args["viewId"] as? Int64,
            let window = NSApp.windows.first(where: {
              ($0.contentViewController as? FlutterViewController)?.viewIdentifier == viewId
            }) else {
        result(FlutterError(code: "window_missing", message: "Flutter view has no window.", details: nil))
        return
      }
      switch call.method {
      case "pickPath":
        let directory = args["directory"] as? Bool == true
        let panel = NSOpenPanel()
        panel.canChooseDirectories = directory
        panel.canChooseFiles = !directory
        panel.canCreateDirectories = directory
        panel.allowsMultipleSelection = false
        if let initialDirectory = args["initialDirectory"] as? String {
          panel.directoryURL = URL(fileURLWithPath: initialDirectory, isDirectory: true)
        }
        if let label = args["label"] as? String { panel.message = label }
        if let extensions = args["extensions"] as? [String] {
          panel.allowedContentTypes = extensions.compactMap { UTType(filenameExtension: $0, conformingTo: .data) }
        }
        panel.beginSheetModal(for: window) { response in
          result(response == .OK ? panel.url?.path : nil)
        }
      case "waitForFullscreen":
        guard let enabled = args["enabled"] as? Bool else {
          result(FlutterError(code: "invalid_arguments", message: "Expected fullscreen state.", details: nil))
          return
        }
        if !self.transitioning.contains(viewId) && window.styleMask.contains(.fullScreen) == enabled {
          result(nil)
          return
        }
        let requestId = UUID()
        self.fullscreenRequests[requestId] = FullscreenRequest(viewId: viewId, enabled: enabled, result: result)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
          guard let request = self?.fullscreenRequests.removeValue(forKey: requestId) else { return }
          request.result(FlutterError(code: "fullscreen_timeout",
                                     message: "AppKit did not finish the fullscreen transition.", details: nil))
        }
      case "configureTitlebar":
        guard let width = args["minimumWidth"] as? Double,
              let height = args["minimumHeight"] as? Double,
              width.isFinite, height.isFinite, width >= 0, height >= 0 else {
          result(FlutterError(code: "invalid_arguments", message: "Expected a logical minimum size.", details: nil))
          return
        }
        let minimumContentSize = NSSize(width: width, height: height)
        let maximumContentSize = window.contentMaxSize
        // 所有视图使用系统标题栏；全尺寸内容保留 Flutter 顶栏，
        // 系统窗口按钮位于其上方。
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.styleMask.insert(.fullSizeContentView)
        // 修改窗口样式后重新应用约束；contentMinSize 优先于 minSize，
        // SDK 也会在切换迷你模式时更新此值。
        window.contentMinSize = minimumContentSize
        window.contentMaxSize = maximumContentSize
        result(nil)
      case "getMinimumSize":
        let content = window.contentMinSize
        result([content.width, content.height])
      case "setNativeWindowButtonsVisible":
        let visible = args["visible"] as? Bool ?? true
        for type in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
          window.standardWindowButton(type)?.isHidden = !visible
        }
        result(nil)
      case "startDragging":
        if let event = NSApp.currentEvent { window.performDrag(with: event) }
        result(nil)
      case "getBounds":
        let rect = window.contentRect(forFrameRect: window.frame)
        let top = NSScreen.screens.first?.frame.maxY ?? 0
        result([rect.minX, top - rect.maxY, rect.width, rect.height])
      case "setBounds":
        guard let x = args["x"] as? Double, let y = args["y"] as? Double,
              let width = args["width"] as? Double, let height = args["height"] as? Double else {
          result(FlutterError(code: "invalid_bounds", message: "Expected logical bounds.", details: nil))
          return
        }
        let top = NSScreen.screens.first?.frame.maxY ?? 0
        let rect = NSRect(x: x, y: top - y - height, width: width, height: height)
        window.setFrame(window.frameRect(forContentRect: rect), display: true,
                        animate: args["animate"] as? Bool ?? false)
        result(nil)
      case "isAlwaysOnTop":
        result(window.level == .floating)
      case "setAlwaysOnTop":
        window.level = args["enabled"] as? Bool == true ? .floating : .normal
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func observeFullscreen(engine: FlutterEngine) {
    let names: [Notification.Name] = [
      NSWindow.willEnterFullScreenNotification, NSWindow.willExitFullScreenNotification,
      NSWindow.didEnterFullScreenNotification, NSWindow.didExitFullScreenNotification,
      NSWindow.willCloseNotification
    ]
    for name in names {
      observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) {
        [weak self] notification in
        guard let self, let window = notification.object as? NSWindow,
              let controller = window.contentViewController as? FlutterViewController,
              controller.engine === engine else { return }
        let viewId = controller.viewIdentifier
        if name == NSWindow.willEnterFullScreenNotification || name == NSWindow.willExitFullScreenNotification {
          self.transitioning.insert(viewId)
          return
        }
        self.transitioning.remove(viewId)
        let closing = name == NSWindow.willCloseNotification
        let fullscreen = window.styleMask.contains(.fullScreen)
        for (id, request) in self.fullscreenRequests.filter({ $0.value.viewId == viewId }) {
          if closing || request.enabled == fullscreen {
            self.fullscreenRequests.removeValue(forKey: id)
            request.result(closing
              ? FlutterError(code: "window_closed", message: "Window closed during fullscreen transition.", details: nil)
              : nil)
          }
        }
      })
    }
  }

  deinit {
    for observer in observers { NotificationCenter.default.removeObserver(observer) }
  }
}
