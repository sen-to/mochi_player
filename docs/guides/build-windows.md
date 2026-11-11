# Windows 构建与排障

基础步骤见根 [README](../../README.md#-从源码运行)。本文补充 Windows 特有的部分。

## 前置

- Visual Studio 2019 及以上（推荐 2022），需勾选「使用 C++ 的桌面开发」工作负载。
- 通过 FVM 使用 [.fvmrc](../../.fvmrc) 锁定的 Flutter 版本。

```bash
fvm flutter pub get
fvm flutter run -d windows
fvm flutter build windows --release
```

## 应用图标

Windows 可执行文件通过 `windows/runner/Runner.rc` 嵌入 `resources/app_icon.ico`，官方窗口宿主也读取此图标资源。ICO 由 `windows/runner/resources/app_icon_<size>.png` 打包而成，包含 16、32、48、64、128、256 像素版本。

这些 PNG 必须是**透明底**：圆角以外 `alpha = 0`。macOS AppIcon 资产按 Apple HIG 保持满幅不透明，四角为白色，直接打包会在任务栏、标题栏和资源管理器中显示一圈白角；Windows 因此单独保存一份透明底导出，与品牌 SVG（`rect width="1024" height="1024" rx="224"`）的圆角范围一致。不要改回读取 macOS 资产。

更新品牌图片后：从 SVG 重新导出透明底 PNG 覆盖 `windows/runner/resources/app_icon_<size>.png`，在项目根目录执行 `powershell -ExecutionPolicy Bypass -File tool/generate_windows_icon.ps1`，提交 PNG 与生成的 ICO，再重新构建。已有快捷方式或任务栏固定项可能保留旧图标缓存，需重新创建或取消固定后重新固定。

## 官方窗口宿主

### 初始最小尺寸

固定 SDK `5ba8961b51` 的 `HostWindow::InitializeFlutterView` 未保存创建参数 `box_constraints`，使 `WM_GETMINMAXINFO` 使用无限制约束。`DesktopWindowService` 创建官方控制器后再次调用 `setConstraints`，让 `HostWindow::SetConstraints` 保存原生约束，不修改 SDK。尺寸值与 mini 恢复规则统一见 [窗口模式](../architecture/playback.md#窗口模式)。

升级 SDK 后核对初始化缺陷是否已修复，再决定移除重复设置；运行 `fvm flutter run -d windows -t tool/smoke/window_constraints_smoke.dart` 检查原生约束、视图隔离、mini 切换与关闭重开。

### 临时关闭 Windows 无障碍语义树

Windows 窗口缩放期间出现 `AccessibilityBridge::CreateRemoveReparentedNodesUpdate` 原生空指针崩溃。为规避该崩溃，正式入口使用 `MochiWidgetsBinding`，在 Windows 上将 `semanticsEnabled` 固定为 false，阻止所有视图生成语义更新；即使系统请求无障碍信息也不重新开启。macOS 保留框架默认行为。该措施会使 Windows 读屏和依赖语义树的辅助工具不可用，是临时规避，不代表引擎缺陷已修复；待固定 SDK 包含修复并完成验收后移除。

### media_kit_video 的无隐式视图兼容补丁

`media_kit_video 2.0.1` 的 Windows 注册代码会解引用 `registrar->GetView()`；官方窗口模式没有隐式视图，导致应用在注册插件时以 `0xc0000005` 退出，故障模块为 `media_kit_video_plugin.dll`。

`windows/CMakeLists.txt` 用 `windows/patches/media_kit_video/media_kit_video_plugin.cc` 替换该插件的单个源文件，其余纹理与渲染实现仍来自锁定的依赖。补丁保留上游 MIT 许可证，使用插件拥有的 Win32 message-only 窗口处理平台线程任务，不依赖主视图或播放器视图；释放输出管理器后再销毁消息窗口。插件不带 viewId 的全屏方法返回 NotImplemented；应用通过视图级 `WindowService` 控制全屏。不修改全局 Pub 缓存或 SDK。

升级 `media_kit_video` 时需核对上游实现是否已支持无隐式视图，再决定移除此源文件替换；同时执行 Windows 启动与 `tool/smoke/windowing_smoke.dart`，检查视频纹理通知及播放器关闭 / 重开。

[main.cpp](../../windows/runner/main.cpp) 创建单个 `FlutterEngine`，注册一次插件；窗口由 Dart 官方 API 创建。

原生扩展通过 `FlutterDesktopPluginRegistrarGetViewById` 定位 HWND：位置与拖动操作指定窗口；普通置顶调用 `SetWindowPos` 的 `HWND_TOPMOST / HWND_NOTOPMOST`；IFileOpenDialog 使用所属视图的父窗口，目录 / 字幕选择取消返回空值。多显示器 / DPI 的尺寸与定位已完成人工验收。

读取窗口样式、获取 / 转换窗口尺寸、调整边框和设置尺寸 / 置顶均检查 Win32 调用结果；失败通过 `window_operation_failed` 返回操作名称与系统错误码。窗口查找与 DPI 结果也检查有效性。

## CI 与验收

CI 按 `.fvmrc` 检出 SDK 并下载预编译引擎，执行项目检查、测试与 Windows Release 构建，产物保留 14 天。

2026-11-11 完成 Windows 人工验收：原生输入与窗口操作、窗口关闭、多显示器 / DPI、真实样片播放与 SMB 转发播放。

## 构建前检查

首次检出或修改 ARB 后，先执行 [README 检查步骤](../../README.md)，再运行 Windows 构建命令。生成目录不提交，配置与语言边界见 [本地化](../architecture/localization.md)。
