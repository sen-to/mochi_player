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

## UI 线程策略（不要回退）

[flutter_window.cpp](../../windows/runner/flutter_window.cpp) 显式把主窗口引擎设置为 `UIThreadPolicy::RunOnSeparateThread`：

> 默认策略会让 UI isolate 与 Win32 消息循环共享线程，`window_manager` / `desktop_multi_window` 的同步 Win32 调用会阻塞该线程，导致打开或激活子窗口后主窗口冻结。

同一文件还注册了 `DesktopMultiWindowSetWindowCreatedCallback`，为每个子引擎注册插件。修改 runner 时这两处都不能删。

## CI

[.github/workflows/windows.yml](../../.github/workflows/windows.yml) 在 `master` 的 push / PR 与手动触发时执行：

1. 从 `.fvmrc` 读取 Flutter 版本（避免版本硬编码）；
2. `flutter pub get` → `flutter analyze` → `flutter test`；
3. `flutter build windows --release`，产物上传为 `mochi-player-windows-x64`（保留 14 天）。

## 已知问题

打开播放器窗口后，媒体库主窗口可能出现鼠标与键盘无响应（渲染仍在继续），关闭播放器窗口也不会恢复。根因是「同进程多 Flutter 引擎」，已在用户文档中列为已知限制（[README.md:218](../../README.md#L218)），处置计划见 [0001](../decisions/0001-multi-window-strategy.md)。
