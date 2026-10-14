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

## 官方窗口宿主

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

本轮开发环境为 macOS，**没有确认 Windows 新宿主构建或运行通过**。需实际验证创建 / 复用 / 关闭、主窗口输入、全屏与 mini、文件选择器、最后进度保存、启动中退出及超时。历史输入冻结不能仅因换成单引擎就宣布已修复。

2026-10-14 [首次 master CI](https://github.com/sen-to/mochi_player/actions/runs/38505530613/job/115662050561) 的依赖、本地化与静态检查通过；测试阶段因 `flutter_tester` 缺少官方 Win32 窗口初始化符号而有 26 个测试文件加载失败，Windows Release 构建尚未执行。测试宿主配置与原因见 [测试指南](testing.md#测试宿主与真实窗口)。修复后必须重新运行 Windows CI 才能确认结果，不能沿用 macOS 的通过结论。

2026-10-14 用户已确认文件对话框手工验收完成，记录见 [测试指南](testing.md)。该确认未单独说明 Windows 平台，因此 Windows COM 对话框的验收仍保留。

## 本地化生成

首次检出或修改 ARB 后，在静态检查、测试与平台构建之前执行：

```bash
fvm flutter pub get
fvm dart run tool/check_l10n.dart
fvm flutter gen-l10n
```

生成文件位于 `lib/l10n/generated/`，不提交到仓库。Windows CI 已显式接入资源检查与生成，规则见 [ADR 0004](../decisions/0004-i18n-l10n.md)。
