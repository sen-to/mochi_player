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

曾出现打开播放器后媒体库主窗口鼠标与键盘无响应（渲染仍在继续）、关闭播放器也不恢复的现象。runner 已通过 UI 线程策略处理同步窗口调用阻塞风险，但完整根因与修复效果仍须运行时验证，不能把「同进程多 Flutter 引擎」直接认定为根因。已知限制见 [README](../../README.md#-已知限制)，处置与验收要求见 [0001](../decisions/0001-multi-window-strategy.md)。

窗口生命周期回归须覆盖：单独关闭播放器、关闭主窗口退出整个应用、播放进度最后一次保存、mini / 全屏退出、重复关闭、启动播放器期间退出与子窗口无响应超时。主窗口关闭即退出的规则尚待实现；构建成功不能替代这些 Windows 运行时检查。
