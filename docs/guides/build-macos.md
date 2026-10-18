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

标题栏配置显式接收所属窗口的最小逻辑内容尺寸，主窗口为 900×600，播放器为 720×405。原生桥在插入 `.fullSizeContentView` 后重新设置 `contentMinSize`；mini 通过视图窗口接口更新同一内容约束为 420×260 并恢复。只维护一套内容约束，不另外设置 `minSize`：[AppKit 文档](https://developer.apple.com/documentation/appkit/nswindow/contentminsize) 明确 `contentMinSize` 在用户缩放时生效且优先于 `minSize`。该补充针对用户报告的 macOS 无限缩小问题；当前 Windows 环境无法确认 AppKit 的实际重置时机，不能将其视为已实测根因。

在 Mac 上执行 `fvm flutter run -d macos --release -t integration_test/window_constraints_smoke.dart`，检查标题栏配置后的内容最小尺寸、mini 约束切换、两个视图隔离和关闭重开，并手工拖动窗口边缘。此次 macOS 原生编译与运行尚待验证。

[AppDelegate.swift](../../macos/Runner/AppDelegate.swift) 创建单个引擎；MainMenu 不再持有隐式 Flutter 窗口。Dart 创建两个独立视图。[NativeWindowControls.swift](../../macos/Runner/NativeWindowControls.swift) 通过 `viewId` 定位 NSWindow，设置透明标题栏、按钮显隐、位置、拖动与普通小窗置顶。文件 / 目录选择使用对应窗口的 NSOpenPanel sheet，全屏请求通过系统完成通知确认后才结束。mini 隐藏系统按钮，退出后恢复。窗口模式交互仍须结合真实视频验收。

项目在 `pubspec.yaml` 启用 `enable-windowing: true`，FVM 固定 main 提交；不要用全局开关代替项目配置。

## 常见问题

| 现象 | 处理 |
| --- | --- |
| 修改了 `core/infrastructure/database/app_database.dart` 表定义后编译报错 | 重新生成 drift 代码：`fvm dart run build_runner build` |
| `flutter analyze` 报生成代码的告警 | drift 生成代码参与静态检查；请先重新生成并检查表定义与生成器版本 |
| `pod install` 报 Flutter-Generated.xcconfig 不存在 | 先执行 `fvm flutter pub get` |
| 构建后无法连接网络媒体源 | 检查对应构建配置的 `network.client` 权限 |

### 原生依赖警告（2026-10-14）

- `POD_CONFIGURATION_DEBUG macro redefined`：`media_kit_video 2.0.1` 的 macOS Podspec 将宏列表中的 `$(inherited)` 加了引号，导致继承的多个宏被拼成一个定义。`Podfile` 的 `pre_install` 钩子仅在内存中修正该插件的设置，再由 CocoaPods 生成配置；不改 pub 缓存或生成头文件，不关闭编译警告。上游 Podspec 修正后删除此钩子。[上游配置](https://github.com/media-kit/media-kit/blob/main/media_kit_video/macos/media_kit_video.podspec)
- Swift Package Manager 提示：项目主动关闭 SPM，已安装的 `media_kit_video 2.0.1` 与 `media_kit_libs_macos_video 1.1.4` 缺少 macOS SPM 支持。继续使用 CocoaPods；升级到支持 SPM 的插件并完成原生依赖迁移后，删除项目关闭开关。仅开启开关不能使插件自动支持 SPM。[上游跟踪](https://github.com/media-kit/media-kit/issues/1399)
- `objc_ownership` / `CVPixelBufferRef`：来自插件 Swift 视频纹理接口生成的 Objective-C 头文件，属于插件接口与编译器桥接问题。上游 README 也记录了同类警告。本项目保留提示，不修改生成头文件或改变像素缓冲区的所有权语义。[上游说明](https://github.com/media-kit/media-kit#notes)
- `Using the Impeller rendering backend`：正常渲染后端信息，不是构建警告。

验证：`pod install --no-repo-update` 成功，生成的宏列表保持各定义独立；macOS Debug 构建成功，本次日志没有宏重定义警告。SPM 提示仍存在。增量构建未输出所有权警告，不代表已修复该生成接口问题。依赖版本与 Podspec 校验值未变，仅更新 Podfile 校验值。

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
