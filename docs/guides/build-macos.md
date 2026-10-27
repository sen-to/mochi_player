# macOS 构建与排障

基础步骤见根 [README](../../README.md#-从源码运行)（FVM 安装、`fvm install`、`fvm flutter run -d macos`）。本文只补充容易踩坑的部分。

## 前置

- Xcode；最低部署目标 macOS 12.0（见 [macos/Podfile](../../macos/Podfile)）。
- 原生插件由 CocoaPods 管理，在 [pubspec.yaml](../../pubspec.yaml) 中通过项目配置关闭 Swift Package Manager：

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
| `network.server` | ✅ | ✅ | SMB 本地 HTTP 回源监听回环端口 |

SMB 回源需要 Debug / Release 均有 `network.server`，服务仍只监听回环地址并检查会话令牌。权限效果与播放证据见 [测试指南](testing.md#验证基线)。

## 窗口外观

[AppDelegate.swift](../../macos/Runner/AppDelegate.swift) 创建单个引擎，Dart 创建视图。[NativeWindowControls.swift](../../macos/Runner/NativeWindowControls.swift) 按 `viewId` 定位 NSWindow：

| 能力 | macOS 适配 |
| --- | --- |
| 标题栏与约束 | `configureTitlebar` 设置透明标题栏 / 按钮，不手动移动红绿灯；插入 `.fullSizeContentView` 后重设所属窗口的 `contentMinSize`，覆盖无限缩小问题 |
| 普通置顶 | `NSWindow.level` 在 `.floating` / `.normal` 间切换；不承诺跨所有 Spaces 或其他应用全屏空间 |
| 全屏 | 官方控制器发起，原生桥等待 AppKit 动画完成通知，最多 5 秒；失败后校准实际状态并允许重试 |
| 文件对话框 | 对应窗口的 NSOpenPanel sheet，目录 / 字幕选择不依赖隐式视图插件 |
| 位置与拖动 | 原生桥只操作指定视图的窗口 |

窗口尺寸、mini 按钮显隐与状态恢复统一见 [窗口模式](../architecture/playback.md#窗口模式)。只维护 `contentMinSize`，不另设 `minSize`；[AppKit 文档](https://developer.apple.com/documentation/appkit/nswindow/contentminsize) 说明前者在用户缩放时生效且优先于后者。

原生约束执行 [尺寸冒烟](testing.md#原生窗口尺寸)，再手工拖动窗口边缘；播放冒烟不能替代该项验收，专项结果见 [验证基线](testing.md#验证基线)。窗口交互仍需使用真实视频检查。

项目使用固定 main SDK 与项目级 `enable-windowing`，不要改用全局配置。

## 常见问题

| 现象 | 处理 |
| --- | --- |
| 修改了 `core/data/database/app_database.dart` 表定义后编译报错 | 重新生成 drift 代码：`fvm dart run build_runner build` |
| `flutter analyze` 报生成代码的告警 | drift 生成代码参与静态检查；请先重新生成并检查表定义与生成器版本 |
| `pod install` 报 Flutter-Generated.xcconfig 不存在 | 先执行 `fvm flutter pub get` |
| 构建后无法连接网络媒体源 | 检查对应构建配置的 `network.client` 权限 |

### 原生依赖警告

- `POD_CONFIGURATION_DEBUG macro redefined`：`media_kit_video 2.0.1` 的 macOS Podspec 将宏列表中的 `$(inherited)` 加了引号，导致继承的多个宏被拼成一个定义。`Podfile` 的 `pre_install` 钩子仅在内存中修正该插件的设置，再由 CocoaPods 生成配置；不改 pub 缓存或生成头文件，不关闭编译警告。上游 Podspec 修正后删除此钩子。[上游配置](https://github.com/media-kit/media-kit/blob/main/media_kit_video/macos/media_kit_video.podspec)
- Swift Package Manager 提示：项目主动关闭 SPM，已安装的 `media_kit_video 2.0.1` 与 `media_kit_libs_macos_video 1.1.4` 缺少 macOS SPM 支持。继续使用 CocoaPods；升级到支持 SPM 的插件并完成原生依赖迁移后，删除项目关闭开关。仅开启开关不能使插件自动支持 SPM。[上游跟踪](https://github.com/media-kit/media-kit/issues/1399)
- `objc_ownership` / `CVPixelBufferRef`：来自插件 Swift 视频纹理接口生成的 Objective-C 头文件，属于插件接口与编译器桥接问题。上游 README 也记录了同类警告。本项目保留提示，不修改生成头文件或改变像素缓冲区的所有权语义。[上游说明](https://github.com/media-kit/media-kit#notes)
- `Using the Impeller rendering backend`：正常渲染后端信息，不是构建警告。

宏修正的构建核对和历史日志见 [验证历史](../history/validation-2026-10.md)，不把增量构建未出现某条警告视为上游接口已经修复。

## 构建命令

```bash
fvm flutter build macos --debug     # 调试构建
fvm flutter build macos --release   # 发布构建
```

## 构建前检查

首次检出或修改 ARB 后，先执行 [统一准备与检查步骤](testing.md#推荐运行顺序)，再运行上述构建命令。生成目录不提交，配置与语言边界见 [本地化](../architecture/localization.md)。
