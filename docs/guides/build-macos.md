# macOS 构建与排障

基础步骤见根 [README](../../README.md#-从源码运行)（FVM 安装、`fvm install`、`fvm flutter run -d macos`）。本文只补充容易踩坑的部分。

## 前置

- Xcode；最低部署目标 macOS 12.0（见 [macos/Podfile](../../macos/Podfile)）。
- 原生插件目前由 CocoaPods 管理。Flutter 3.44 起默认启用 Swift Package Manager；本项目尚未完成 SPM 迁移，因此在 [pubspec.yaml](../../pubspec.yaml) 中仅对本项目关闭 SPM：

```yaml
flutter:
  config:
    enable-swift-package-manager: false
```

这是一项过渡设置，不要改用 `flutter config --no-enable-swift-package-manager` 作为项目要求，因为该命令修改的是当前用户的 Flutter 全局配置。Flutter 官方说明 CocoaPods registry 将于 2026-12-02 转为只读；在此之前应确认所有原生插件的 SPM 兼容性并安排迁移。迁移完成后删除这段项目配置。[官方说明](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers)

## 沙箱与权限

macOS 目标开启了 App Sandbox，权限在 [DebugProfile.entitlements](../../macos/Runner/DebugProfile.entitlements) 与 [Release.entitlements](../../macos/Runner/Release.entitlements) 中声明：

| 权限 | Debug | Release | 用途 |
| --- | --- | --- | --- |
| `app-sandbox` | ✅ | ✅ | 沙箱 |
| `network.client` | ✅ | ✅ | 访问 WebDAV / SMB / TMDB |
| `files.user-selected.read-only` | ✅ | ✅ | 用户选择本地目录 |
| `allow-jit` | ✅ | — | Flutter 调试所需 |
| `network.server` | ✅ | ❌ | **仅 Debug 具备** |

需要注意：**Release 版本没有 `network.server`**。若按 [0005](../decisions/0005-smb-playback-path.md) 引入本地 HTTP 回源服务（监听回环端口），必须先为 Release 补上该权限，否则沙箱会拒绝监听。

## 窗口外观

主窗口使用隐藏标题栏，原生红绿灯按钮的位置与显隐由 Swift 代码控制（[MainFlutterWindow.swift](../../macos/Runner/MainFlutterWindow.swift)），并监听窗口缩放与全屏通知重新定位。mini 播放器模式下会隐藏原生按钮。修改窗口外观时需同时考虑这段原生逻辑。

## 常见问题

| 现象 | 处理 |
| --- | --- |
| 修改了 `core/infrastructure/database/app_database.dart` 表定义后编译报错 | 重新生成 drift 代码：`fvm dart run build_runner build` |
| `flutter analyze` 报生成代码的告警 | drift 生成代码参与静态检查；请先重新生成并检查表定义与生成器版本 |
| `pod install` 报 Flutter-Generated.xcconfig 不存在 | 先执行 `fvm flutter pub get` |
| 构建后无法连接网络媒体源 | 检查对应构建配置的 `network.client` 权限 |

## 构建命令

```bash
fvm flutter build macos --debug     # 调试构建
fvm flutter build macos --release   # 发布构建
```

## 本地化生成

首次检出或修改 ARB 后，在静态检查、测试与平台构建之前执行：

```bash
fvm flutter pub get
fvm dart run tool/check_l10n.dart
fvm flutter gen-l10n
```

生成文件位于 `lib/l10n/generated/`，不提交到仓库。Windows CI 已显式接入资源检查与生成，规则见 [ADR 0004](../decisions/0004-i18n-l10n.md)。
