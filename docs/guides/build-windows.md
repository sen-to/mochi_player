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

Windows 可执行文件通过 `windows/runner/Runner.rc` 嵌入 `resources/app_icon.ico`，官方窗口宿主也读取此图标资源。该 ICO 复用 macOS 已提交的 Mochi 品牌 PNG，包含 16、32、64、128、256 像素版本。更新品牌图片后，在项目根目录执行 `powershell -ExecutionPolicy Bypass -File tool/generate_windows_icon.ps1`，提交生成的 ICO，再重新构建 Windows 应用。已有快捷方式或任务栏固定项可能保留旧图标缓存，需重新创建或取消固定后重新固定。

## 官方窗口宿主

### 初始最小尺寸

固定 SDK `5ba8961b51` 的 `HostWindow::InitializeFlutterView` 没有将创建参数的 `box_constraints` 保存到宿主字段，导致 `WM_GETMINMAXINFO` 使用默认无限制约束。`DesktopWindowService` 在 Windows 官方控制器创建后再次调用 `setConstraints`，通过 SDK 的 `HostWindow::SetConstraints` 保存原生约束，不修改 SDK。主窗口最小内容尺寸为 900×600，播放器为 720×405；mini 模式为 420×260，退出时恢复常规约束。尺寸单位为逻辑像素。

升级 SDK 后核对该初始化缺陷是否已修复，再决定是否移除重复设置；使用 `integration_test/window_constraints_smoke.dart` 查询真实原生缩放限制，验证窗口间隔离、mini 约束切换与关闭重开。

### 临时关闭 Windows 无障碍语义树

Windows 窗口缩放期间出现 `AccessibilityBridge::CreateRemoveReparentedNodesUpdate` 原生空指针崩溃。按用户要求，正式入口使用 `MochiWidgetsBinding`，在 Windows 上将 `semanticsEnabled` 固定为 false，阻止所有视图生成语义更新；即使系统请求无障碍信息也不重新开启。macOS 保留框架默认行为。该措施会使 Windows 读屏和依赖语义树的辅助工具不可用，是临时规避，不代表引擎缺陷已修复；待固定 SDK 包含修复并完成验收后移除。此前 AppSlider 的局部 Overlay 规避已撤回。

### media_kit_video 的无隐式视图兼容补丁

`media_kit_video 2.0.1` 的 Windows 注册代码会解引用 `registrar->GetView()`；官方窗口模式没有隐式视图，导致应用在注册插件时以 `0xc0000005` 退出，故障模块为 `media_kit_video_plugin.dll`。

`windows/CMakeLists.txt` 用 `windows/patches/media_kit_video/media_kit_video_plugin.cc` 替换该插件的单个源文件，其余纹理与渲染实现仍来自锁定的依赖。补丁保留上游 MIT 许可证，使用插件拥有的 Win32 message-only 窗口处理平台线程任务，不依赖主视图或播放器视图；释放输出管理器后再销毁消息窗口。插件旧的无 viewId 全屏方法返回 NotImplemented，应用继续使用视图级 `WindowService`。不修改全局 Pub 缓存或 SDK。

升级 `media_kit_video` 时需核对上游实现是否已支持无隐式视图，再决定移除此源文件替换；同时执行 Windows 启动与 `integration_test/windowing_smoke.dart`，检查视频纹理通知及播放器关闭 / 重开。

[main.cpp](../../windows/runner/main.cpp) 创建单个 `FlutterEngine`，注册一次插件；窗口由 Dart 官方 API 创建。旧 `FlutterWindow`、多引擎插件回调与 `RunOnSeparateThread` 补丁已删除，不应复制旧宿主回来。

原生扩展根据 `FlutterDesktopPluginRegistrarGetViewById` 定位 HWND，负责官方 API 尚未提供的位置、拖动、普通 mini 置顶，以及按视图定位父窗口的 IFileOpenDialog。目录选择和字幕扩展名过滤取消时返回空值。需要检查多显示器 / DPI 下的尺寸与定位。

读取窗口样式、获取 / 转换窗口尺寸、调整边框和设置尺寸 / 置顶均检查 Win32 调用结果；失败通过 `window_operation_failed` 返回操作名称与系统错误码，不再向 Dart 返回成功。窗口查找与 DPI 结果也检查有效性。

### 旧多引擎代码清理（2026-10-14）

- 删除 `runner/flutter_window.cpp/.h` 与 `runner/win32_window.cpp/.h`，并移除 CMake 源文件引用。
- 随旧宿主删除 `UIThreadPolicy::RunOnSeparateThread` 输入冻结补丁、`DesktopMultiWindowSetWindowCreatedCallback` 子引擎插件注册，以及 `SetQuitOnClose(false)` 退出保活设置。
- 从依赖、生成的插件注册和 CMake 插件列表移除 `desktop_multi_window`、`window_manager`、`screen_retriever`；依赖隐式视图的 `file_selector` 也已移除。
- 本次复查移除旧 `Win32Window` 遗留的 `dwmapi.lib` 链接项；保留 COM 文件对话框及命令行解析使用的 `ole32.lib`、`shell32.lib`、`uuid.lib`。

当前保留单引擎启动、一次插件注册、标准 Win32 消息循环，以及按 viewId 定位窗口的原生扩展。没有保留旧多引擎兼容分支。源码清理完成不代表 Windows 输入冻结回归已通过。

## CI 与验收

CI 从 `.fvmrc` 读取完整 main 提交，通过 Git 检出 SDK，再下载预编译引擎；不把提交号交给只接受发布版本的安装参数。流程保留依赖、l10n、静态检查、测试与 Windows Release 构建，产物保留 14 天。SDK 的旧 Material/Cupertino 导入弃用提示暂不作为失败，错误与警告仍会失败。

开发环境为 macOS；原生构建修复后，用户已确认 Windows CI 成功，**Windows 应用的运行时人工验收仍未确认**。需实际验证创建 / 复用 / 关闭、主窗口输入、全屏与 mini、文件选择器、最后进度保存、启动中退出及超时。构建通过或换成单引擎不能直接证明历史输入冻结已修复。当前证据统一见 [测试指南](testing.md#当前验证基线2026-10-14)。

CI 曾遇到测试宿主缺少 `InternalFlutterWindows_WindowManager_Initialize`，随后在测试阶段隔离原生窗口初始化；又遇到 Windows 头文件 `small` 宏替换局部变量，已将变量改为 `int32_value`。原因、历史证据见 [验证历史](../history/validation-2026-10.md)，测试宿主策略见 [测试指南](testing.md#测试宿主与真实窗口)。

2026-10-14 用户已确认文件对话框手工验收完成，记录见 [测试指南](testing.md)。该确认未单独说明 Windows 平台，因此 Windows COM 对话框的验收仍保留。

## 本地化生成

首次检出或修改 ARB 后，在静态检查、测试与平台构建之前执行：

```bash
fvm flutter pub get
fvm dart run tool/check_l10n.dart
fvm flutter gen-l10n
```

生成文件位于 `lib/l10n/generated/`，不提交到仓库。Windows CI 已显式接入资源检查与生成，规则见 [ADR 0004](../decisions/0004-i18n-l10n.md)。
