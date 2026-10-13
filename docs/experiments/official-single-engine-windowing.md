# 官方单引擎多窗口：验证结论与重构依据

首轮实验：2026-10-12；用户人工验收、Release 验证与归档：2026-10-13。

**macOS 基础路径已证明可行，活动原型完成本轮任务后归档；生产项目继续使用现有多引擎窗口后端。** 未验证 Windows、系统 PiP 或完整业务迁移，不将删除实验目录视为迁移验收通过。

## 1. SDK、通道与发布能力

### stable 的底层能力与官方窗口 API

项目 SDK 仍为 Flutter 3.47.2 stable。其 macOS `FlutterViewController` 提供连接现有 `FlutterEngine` 的构造接口，多视图底层能力存在；本轮没有在 stable 上自行实现原生多窗口宿主，也没有声称该路线运行验证通过。

官方 Dart Desktop Windowing API 的正常启用则有通道门槛：

1. 3.47.2 的 `packages/flutter_tools/lib/src/features.dart` 中，`windowingFeature` 只配置 `master: FeatureChannelSetting(available: true)`，stable / beta 使用默认不可用设置。
2. `packages/flutter_tools/lib/src/flutter_features.dart` 的 `FlutterFeatureFlags.isEnabled` 先检查当前通道的 `available`，不可用时直接返回 false，再读取环境变量、项目配置与全局开关。
3. SDK 中的开发侧设置字段叫 `master`；main 和非 stable / beta 的固定提交快照如何处理，由该 SDK 的 `getSettingForChannel` 决定。不能只看字段名推断 main 不可用，也不能说普通开关能解锁 stable。

官方公告把这套 API 定义为 main 上的实验能力。本次使用的 API 是 `WindowController`、`WindowManager` / `WindowRegistry` 和 `runWidget`；本机 stable 中的 `RegularWindowController` 名称已与实验 SDK 不同，未提供双版本兼容代码。源码核对依据是本机 SDK 的上述文件及本文末尾固定提交链接；不在仓库额外保存机器元数据。

### FVM 与固定版本

2026-10-13 上游复核：官方 `stable` 分支与最新非预发布标签 `3.47.7` 同指向 `abaf9c523780a608bd46686fd5e53740a07077f8`，提交时间为北京时间 2026-10-09 00:51:21（提交时间不等同于发行日期）。读取该提交的 `windowingFeature` 后，确认仍只有开发侧 `available=true`，普通开关未向 stable 开放。该结论不仅来自项目旧 SDK；核对方式为实时 `git ls-remote` 比较 stable 分支与版本标签，并读取该提交的功能定义。生产项目本轮不升级版本。

官方推荐 stable 用于生产发布，main 的测试充分程度低于 stable / beta，可能包含严重回归。固定提交只避免后续代码漂移、方便复现，不使 main 自动获得 stable 的可靠性。若未来为窗口 API 采用 main，必须固定提交并自行完成项目插件、两平台 Release 与业务回归，不能把本轮短片 / 窗口通过当作整个 SDK 已充分验证。参考 [官方通道说明](https://docs.flutter.dev/install/upgrade#other-channels)。

FVM 负责下载、缓存和选择 SDK，不改变 SDK 自身的功能门槛。它支持通道名和 Git 提交号。后续实验或迁移应固定已验证提交，而非直接追踪会变化的 `main`：

```json
{
  "flutter": "b314ad53146b1bde55b60197a35183fb530aac0a"
}
```

在对应的独立项目里执行 `fvm use`，按配置安装 / 关联 SDK。此示例不是要求修改生产项目根 `.fvmrc`。本次 SDK 元数据为 Flutter `3.49.0-0.2.pre`、Dart `3.15.0-18.0.dev`，提交时间 `2026-10-12T08:35:20Z`，上述版本信息来自本次实验 SDK 的 `flutter --version --machine` 输出。

正常使用官方 SDK 工具即可下载对应预编译引擎产物，本轮没有修改 Flutter 源码或本地编译 C++ 引擎。Git 下载 SDK 不等于自行编译 Flutter 引擎。

### 实验开关同时适用于 Debug 和 Release

原型在自己的 pubspec 中配置：

```yaml
flutter:
  config:
    enable-windowing: true
    enable-swift-package-manager: false
```

macOS Debug 基础窗口 14 项、媒体模式 16 项断言通过。随后 `flutter build macos --release --dart-define=WITH_MEDIA=true` 成功，生成约 92.3 MB 的 `.app`；直接启动 Release 包，创建两个窗口并显示测试视频，进程路径确认为 Release 目录。不是只能通过 `flutter run -d macos` 使用，也不要求应用使用者安装 Flutter。

Release 结果通过构建输出、直接启动后的窗口画面与运行进程路径确认。完整项目 Release、Windows Release、对外分发签名 / 公证尚未验证。「实验 API」表示维护时需接受接口变化，不表示不能打包或禁止发布。

## 2. 系统 PiP 与普通 mini 窗口

用户希望 macOS 小窗采用系统画中画 PiP。本轮测试的是普通 Flutter 播放器窗口缩小到 400×300，**没有接入或测试系统 PiP**。

| 方案 | 窗口责任 | 与 Flutter windowing 的关系 | 当前状态 |
| --- | --- | --- | --- |
| 普通 Flutter mini 窗口 | 应用调整窗口尺寸、控制层和置顶；可调用系统窗口接口 | 可使用当前多引擎后端或未来单引擎窗口 API | 缩小 / 恢复 / 全屏基础验证通过，官方后端置顶扩展未测试 |
| macOS 系统 PiP | AVKit 管理画中画窗口，应用提供视频内容和播放控制 | 独立于 Flutter 官方窗口 API；stable 应用也可原生桥接接入 | 用户期望的候选方向，尚未实现 / 验证 |

Apple 提供 `AVPlayerView.allowsPictureInPicturePlayback` 和 `AVPictureInPictureController`。公开内容源接口可以接入 player layer 或 sample buffer display layer；本机 SDK 标注后者内容源接入适用于 macOS 12 及以后。系统 PiP 不接收任意 Flutter Widget，也不能把 libmpv 句柄直接当作 AVPlayer。

项目当前使用 media_kit/libmpv 和 Flutter 视频纹理。后续需要独立验证从当前视频输出接入 AVKit 的路径、帧格式 / 时间戳、字幕呈现、控制事件、回到普通播放器、释放与进度保存。优先保持同一播放会话，不因 PiP 示例使用 AVPlayer 就未经决策更换项目播放引擎，也不为画中画另开一个独立播放器。

如保留普通 mini 窗口，macOS 的窗口 level / Windows 的 `SetWindowPos(HWND_TOPMOST)` 可作为原生扩展方案，仍需绑定正确窗口并测试。缺少 Flutter 通用置顶方法不是单引擎方案的根本否决条件。macOS 系统 PiP 方案不自动证明 Windows 有相同接口或产品行为；Windows 小窗方案需分别确认。

## 3. 已取得的实验结果

原生宿主来自固定提交的官方 `examples/multiple_windows`，只创建一个 `FlutterEngine`。两个窗口回调使用同一 isolate 和不同 rootView ID；宿主另保留初始隐式视图 0。主窗口为 1，首个播放器为 2；关闭播放器后引擎视图集合回到 `[0,1]`，不是要求总视图数等于可见窗口数。

| 能力 | macOS 结果 | 证据与边界 |
| --- | --- | --- |
| 两个独立窗口、共享状态 | 通过 | 原生单引擎宿主、同一 isolate、不同视图；计数双向更新 |
| 鼠标、英文输入、焦点切换 | 通过 | 两窗口各自保留 `main123` / `player456`；播放时主窗口继续响应 |
| 中文输入法 / 复制粘贴 | 用户人工验收通过 | 2026-10-13 用户确认；未记录具体输入法、操作次数和长时间覆盖 |
| 缩小、最小化、恢复 / 激活、全屏 | 通过 | 控制器断言和用户人工确认；缩小不是系统 PiP |
| 关闭与重开播放器 | 通过 | 原生关闭后主窗口存在；连续三次重开后无额外引擎视图残留 |
| media_kit 视频纹理和 seek | 通过，限定素材 | 移动 RGB 色条 AVI，160×90；纹理 ID、解码尺寸、seek 到 2 秒及实际画面验证，不代表 H.264 / HDR / 硬解 |
| SharedPreferences 插件 | 通过 | 写入 / reload；独立实验沙箱，不触碰生产设置 |
| 主窗口关闭 / 播放器聚焦时 Cmd+Q | 通过 | 先暂停、保存实验进度、释放播放器、关闭子窗口，再退出进程；进度保存使用 SharedPreferences，不代表 SQLite 退出验收 |
| macOS Release 构建与基本运行 | 通过 | 直接启动发布包，双窗口与视频显示，不依赖 flutter run |
| 无障碍 / VoiceOver | 待查 | 自动化 AX 树只暴露原生框架；不能据此判定 VoiceOver 缺陷 |
| Windows、系统 PiP、完整项目插件 | 未验证 | 本轮成功不能推广到这些能力 |

用户在 2026-10-13 明确确认三组人工验收成功：两窗口文本输入 / 复制粘贴 / 焦点切换；播放时主窗口响应及 Mini / Fullscreen；播放器单独关闭与主窗口 / Cmd+Q 整体退出。该确认限定于本原型与测试素材，不扩大为全部真实媒体或长期运行通过。

历史日志显示的正常退出顺序为：暂停 → 保存实验进度 → 释放播放器 / 关闭子窗口 → 应用退出。基础模式通过 14 项断言、媒体模式通过 16 项断言。用户人工确认与这些自动断言分别记录；机器日志已移出仓库，后续不能把本文当作可直接重跑的自动化测试套件。

实验依赖为 media_kit 1.2.6、media_kit_video 2.0.1、media_kit_libs_video 1.0.7；原型不使用 desktop_multi_window / window_manager，也不访问生产数据库。

## 4. 后续验证清单

以下是正式迁移前或对应功能实施时的门槛，不要求为了保留本轮可行性结论而长期维护原型。

| 优先级 / 验证项 | 必须取得的证据 | 当前判断 |
| --- | --- | --- |
| P0：Windows 单引擎窗口 | 固定 SDK 的 Debug / Release，创建 / 聚焦 / 输入 / 全屏 / 关闭重开、播放期间主窗口响应、整体退出 | 项目目标平台，迁移前必须验证；当前 macOS 环境无法代替 |
| P0：macOS 系统 PiP | 当前 libmpv 视频接入公开 AVKit 接口，画面连续刷新、暂停 / seek / 恢复、字幕、返回正常播放器、关闭主窗口后 PiP 结束 | 用户小窗目标，须单独制作内容源实验；现有普通小窗原型未覆盖 |
| P0：真实播放链路 | 项目目标媒体的音视频、音轨 / 字幕、切集、seek、全屏与 PiP / mini 切换、资源释放；网络路径按对应 ADR 的已支持范围 | RGB AVI 只能证明纹理路径，不能替代播放引擎能力基线；SMB 原有失败按 ADR 0005 单独处理 |
| P0：数据与退出 | 在单引擎原型或隔离迁移检出接入真实 drift / SQLite；进度 / 收藏刷新；关闭重开后最后快照仍在；重复退出、打开 / 切集中退出、保存失败与无响应有界结束 | 原型的内存共享和 SharedPreferences 保存不能替代数据库业务验收 |
| P0：项目插件与 SDK 升级 | path_provider、file_selector、偏好和项目原生通道能绑定正确服务 / 窗口；生成代码、l10n 双窗口切换、全量回归与两平台 Release | 当前 media_kit / 偏好成功不代表其他插件已兼容；不要直接保留旧 window_manager 的隐式主窗口假设 |
| P1：持续运行与窗口边界 | 长时间播放、重复打开 / 替换 / 关闭，资源趋势、后台 / 遮挡 / 多显示器与 DPI、全屏跨 Spaces；复查 frame-time 诊断 | 原型仅三次重开和短片，未证明无长期泄漏或多显示器问题 |
| P1：无障碍与分发 | VoiceOver / 键盘导航；发布包签名 / 公证及目标环境安装启动 | 单纯 AX 工具读取或本机 Release 启动不能替代 |

后续迁移需重新评估单引擎下的窗口身份、Provider / 播放会话所有权、数据库订阅和退出职责；不能仅将旧跨引擎 RPC 外壳长期保留为兼容层。验证新流程后删除旧后端和失效协议，不长期维护两套业务实现。此处是重构依据，不是本轮开始重构。

## 5. 原型退役与后续复现

本轮「macOS 基础窗口与 Release 是否可行」已有足够结论。活动目录 `experiments/official_windowing/` 已移除，根 analyzer 的实验目录排除也随之移除。仓库只保留本 Markdown 与 ADR：不提交实验 JSON / JSONL、源码压缩包、SDK、Pods、构建输出或生成视频。

原始源码、锁文件和日志暂存于本机临时目录，供当前会话需要时恢复；临时副本不保证长期保存，也不是其他开发者的依赖。仓库不再提供完整历史原型的直接复现包。需要重新验证时，在独立临时项目固定上述 SDK 提交，以该提交的 [官方 multiple_windows 示例](https://github.com/flutter/flutter/tree/b314ad53146b1bde55b60197a35183fb530aac0a/examples/multiple_windows) 为宿主，按第 4 节的目标接入所需插件和场景，重新记录结果。

使用 FVM 时，在独立项目的 `.fvmrc` 写固定提交号，再执行 `fvm use`。确认 `fvm flutter --version`、项目 `enable-windowing` 开关及 SDK 路径正确。macOS / Windows 的 Debug 和 Release 分别验收，不依赖全局 Flutter，也不修改生产项目根 `.fvmrc`。这是后续验证方法，不代表尚未测试的平台或系统 PiP 已通过。

### 已定位的问题

- 全局 Flutter 与实验 SDK 的 API 不一致，曾导致 `WindowController` / `WindowManager.initialWindows` 编译错误；使用固定 SDK、恢复锁文件中的依赖后消失。这不是原型在已验证 SDK 下无法运行。
- 官方无插件宿主没有 RunnerTests target，自动生成 Podfile 却引用它；实验删除该不存在的 target，在唯一引擎注册插件后构建成功。
- 初始断言把所有引擎视图都当作可见窗口，已改为严格核对初始集合 / 新增视图 / 关闭后集合；实验 UI 与默认视频控制层的小窗口溢出也已修正。这些是测试自身修正，不作为官方窗口缺陷。
- 交互期间出现一次 `Reported frame time is older than the last one; clamping`，未观察冻结；是否有可复现性能影响仍待 P1 验证。
- main 提示当前 media_kit_video / media_kit_libs_macos_video 尚不支持 Swift Package Manager，未来构建默认变化需跟踪；本轮 CocoaPods Debug / Release 成功不保证未来 SDK 无构建问题。

## 6. 来源与决策入口

- [ADR 0001](../decisions/0001-multi-window-strategy.md)：生命周期规则与双平台迁移门槛。
- [ADR 0002](../decisions/0002-playback-engine.md)：当前播放引擎边界；系统 PiP 不自动意味着更换后端。
- [Flutter 官方公告（2026-08-24）](https://flutter.dev/blog/desktop-windowing-apis)：main 的实验窗口 API。
- [项目 stable 提交的功能定义](https://github.com/flutter/flutter/blob/d3b14c876900e553bc736ca19295fc09e3853e8e/packages/flutter_tools/lib/src/features.dart) 与 [启用检查](https://github.com/flutter/flutter/blob/d3b14c876900e553bc736ca19295fc09e3853e8e/packages/flutter_tools/lib/src/flutter_features.dart)。
- [该 stable 提交的 macOS 视图接口](https://github.com/flutter/flutter/blob/d3b14c876900e553bc736ca19295fc09e3853e8e/engine/src/flutter/shell/platform/darwin/macos/framework/Headers/FlutterViewController.h)。接口存在不是 stable 原型已运行的证据。
- [实验提交的窗口 API](https://github.com/flutter/flutter/blob/b314ad53146b1bde55b60197a35183fb530aac0a/packages/flutter/lib/src/widgets/_window.dart) 与 [官方宿主](https://github.com/flutter/flutter/tree/b314ad53146b1bde55b60197a35183fb530aac0a/examples/multiple_windows)。
- [FVM 命令说明](https://fvm.app/documentation/guides/basic-commands)：支持通道名 / 提交号。
- [AVPlayerView PiP 开关](https://developer.apple.com/documentation/avkit/avplayerview/allowspictureinpictureplayback)、[AVPictureInPictureController](https://developer.apple.com/documentation/avkit/avpictureinpicturecontroller)、[sample buffer 内容源](https://developer.apple.com/documentation/avkit/avpictureinpicturecontroller/contentsource-swift.class/init(samplebufferdisplaylayer:playbackdelegate:))。
