# 官方单引擎多窗口：历史原型依据

实验与核查日期：2026-10-12～13；人工确认、Release 验证与归档：10-13。以下描述仅针对当时 SDK 与原型，不代表上游现状或正式项目完整验收。正式迁移依据见 [ADR 0001](../decisions/0001-multi-window-strategy.md)，后续验证见 [阶段记录](validation-2026-10.md) 与 [测试指南](../guides/testing.md)。

## SDK 与通道核查

| 对象 | 当时记录 | 结论边界 |
| --- | --- | --- |
| 项目原 SDK | Flutter 3.47.2 stable，提交 `d3b14c876900e553bc736ca19295fc09e3853e8e` | macOS 有连接既有引擎的视图接口；未在 stable 自建原生多窗口宿主或验证该路线 |
| 10-13 stable 复核 | `stable` 分支与非预发布标签 `3.47.7` 同指向 `abaf9c523780a608bd46686fd5e53740a07077f8`；提交时间为北京时间 10-09 00:51:21，非发行日期 | 通过 `git ls-remote` 比较分支 / 标签并读取功能定义；该提交的普通开关仍未向 stable 开放实验窗口 API |
| 原型 SDK | `b314ad53146b1bde55b60197a35183fb530aac0a`，Flutter `3.49.0-0.2.pre`、Dart `3.15.0-18.0.dev`；提交时间 `2026-10-12T08:35:20Z` | 来自实验 SDK 的 `flutter --version --machine`；与后续正式迁移固定提交不同 |

核查时 `features.dart` 的 `windowingFeature` 仅配置开发侧 `master: FeatureChannelSetting(available: true)`；`FlutterFeatureFlags.isEnabled` 先检查通道可用性，再读取环境变量、项目与全局配置。main / 固定提交如何映射由 `getSettingForChannel` 决定，不能只看字段名；普通 run 参数不能解锁当时 stable 的同一套 API。[功能定义](https://github.com/flutter/flutter/blob/d3b14c876900e553bc736ca19295fc09e3853e8e/packages/flutter_tools/lib/src/features.dart)、[启用检查](https://github.com/flutter/flutter/blob/d3b14c876900e553bc736ca19295fc09e3853e8e/packages/flutter_tools/lib/src/flutter_features.dart)、[stable macOS 视图接口](https://github.com/flutter/flutter/blob/d3b14c876900e553bc736ca19295fc09e3853e8e/engine/src/flutter/shell/platform/darwin/macos/framework/Headers/FlutterViewController.h)。

[官方公告（2026-08-24）](https://flutter.dev/blog/desktop-windowing-apis) 将 API 定义为 main 的实验能力；[通道说明](https://docs.flutter.dev/install/upgrade#other-channels) 推荐生产使用 stable。固定提交方便复现，但不能赋予 main 与 stable 相同的可靠性。此处为历史核查，升级时须重新确认。

FVM 下载、缓存并选择 SDK，不改变功能门槛，也不要求自行编译 C++ 引擎。原型使用对应预编译引擎；[FVM 支持通道名与 Git 提交号](https://fvm.app/documentation/guides/basic-commands)。

## 原型与验证范围

宿主来自实验提交的 [official multiple_windows 示例](https://github.com/flutter/flutter/tree/b314ad53146b1bde55b60197a35183fb530aac0a/examples/multiple_windows)，只创建一个 FlutterEngine。两个可见窗口在同一 isolate、使用不同 rootView ID；初始隐式视图 0 仍在，主窗口为 1、首个播放器为 2，关闭后集合回到 `[0,1]`。引擎视图总数不等于可见窗口数。

原型使用该提交的 [WindowController / WindowManager / WindowRegistry 与 runWidget](https://github.com/flutter/flutter/blob/b314ad53146b1bde55b60197a35183fb530aac0a/packages/flutter/lib/src/widgets/_window.dart)。项目配置开启 `enable-windowing`、关闭 SPM；插件为 media_kit 1.2.6、media_kit_video 2.0.1、media_kit_libs_video 1.0.7，不使用旧窗口插件，不访问生产数据库 / 偏好。

| 验证项 | 记录结果 | 范围与限制 |
| --- | --- | --- |
| 双窗口与状态 | macOS 通过 | 单引擎同 isolate、不同视图，计数双向更新；基础模式 14 项、媒体模式 16 项断言通过 |
| 输入与响应 | 自动检查英文输入 / 焦点；10-13 人工验收反馈确认中文、复制粘贴及播放时主窗口响应 | 两窗口分别保留输入；未记录输入法、操作次数或长期覆盖 |
| 窗口操作 | 缩至 400×300、最小化、恢复 / 激活、全屏通过；人工验收反馈确认 | 普通 mini，不是系统 PiP；原型未测试置顶扩展 |
| 播放器关闭重开 | 通过 | 原生关闭后主窗口存在，连续三次重开后视图集合无额外残留；不证明长期无泄漏 |
| 视频与 seek | 通过，限定素材 | 160×90 移动 RGB 色条 AVI，核对纹理、解码尺寸、seek 到 2 秒及画面；不代表 H.264 / HDR / 硬解 |
| 偏好与整体退出 | 插件写入 / reload、主窗口关闭与播放器聚焦时 Cmd+Q 通过，人工验收反馈确认退出行为 | 顺序为暂停 → 保存实验进度 → 释放播放器 / 关闭子窗口 → 退出；使用隔离 SharedPreferences，未验证 SQLite 退出 |
| macOS Release | 构建及基本运行通过 | `flutter build macos --release --dart-define=WITH_MEDIA=true` 生成约 92.3 MB 应用；直接启动后核对双窗口、视频与 Release 进程路径，证明不依赖 flutter run；未签名 / 公证验收 |
| 无障碍 | 未确认 | AX 工具只读到原生框架，不足以判断 VoiceOver 缺陷 |
| Windows、完整项目插件与真实媒体 | 未验证 | 不从 macOS 原型推广为目标平台或业务已通过 |

10-13 的三组人工验收反馈对应：文本输入 / 焦点；播放时主窗口响应及 mini / 全屏；播放器单独关闭与主窗口 / Cmd+Q 整体退出。原型没有覆盖真实媒体、长期运行或所有插件。

## 关键问题与测试修正

| 现象 | 处理与结论 |
| --- | --- |
| WindowController / initialWindows 编译错误 | 全局 stable 与实验 SDK API 不一致；选择固定 SDK 并恢复锁定依赖后消失，没有增加双版本兼容代码 |
| Podfile 引用不存在的 RunnerTests | 官方无插件宿主没有该 target；原型删除其引用，并在唯一引擎注册插件后构建成功 |
| 视图数量断言不正确、小窗溢出 | 改为检查初始 / 新增 / 关闭后视图集合，并调整实验布局；属于测试自身修正，不作为官方窗口缺陷 |
| frame-time clamping | 交互时出现一次日志，未观察冻结；未证明没有可复现性能或长期稳定性问题 |
| SPM 提示 | 当时相关 media_kit 插件缺少 macOS SPM 支持，CocoaPods Debug / Release 成功；不保证未来 SDK 构建兼容 |

## mini 与系统 PiP 的调研边界

原型只测试普通 Flutter 小窗。Apple 的 [AVPlayerView PiP 开关](https://developer.apple.com/documentation/avkit/avplayerview/allowspictureinpictureplayback)、[AVPictureInPictureController](https://developer.apple.com/documentation/avkit/avpictureinpicturecontroller) 与 [sample buffer 内容源](https://developer.apple.com/documentation/avkit/avpictureinpicturecontroller/contentsource-swift.class/init(samplebufferdisplaylayer:playbackdelegate:)) 属于独立 AVKit 接入；实验环境的 SDK 标注该 sample buffer 内容源适用于 macOS 12+。系统 PiP 不接收任意 Flutter Widget 或 libmpv 句柄，原型未实现视频帧、字幕合成或控制 / 生命周期桥接，也未验证 Windows 对应方案。

缺少 Flutter 通用置顶 API 不妨碍普通 mini 经原生窗口层级接口实现，但原型未测试该扩展。10-14 已选择继续 mini、暂缓系统 PiP；该候选调研不再作为实施待办，取舍与重新评估条件统一见 [ADR 0001](../decisions/0001-multi-window-strategy.md)，播放后端约束见 [ADR 0002](../decisions/0002-playback-engine.md)。

## 退役与后续验证

`experiments/official_windowing/` 及其 analyzer 排除已移除，不保留实验 JSON / JSONL、压缩包、SDK、Pods、构建输出或生成视频。原始源码 / 锁文件 / 日志当时暂存在本机临时目录，不保证长期保存，仓库不提供完整历史复现包。

若需重新验证，应在独立临时项目固定上述实验提交、使用对应官方示例和项目级窗口开关，通过 FVM 选择 SDK 并核对版本，不修改生产项目的 `.fvmrc`。API 已变化时须调整验证入口，不能直接把本文当作可重跑的测试套件。

正式业务需分别验证 Windows Debug / Release、项目插件的视图绑定、真实媒体 / 字幕 / 硬解、SQLite 进度与退出竞争、长时间运行、多显示器 / DPI / Spaces、无障碍和签名 / 安装。原型退役不表示这些项目通过；具体命令和当前待验收范围统一维护在 [测试指南](../guides/testing.md) 与 [实施状态](../status.md)，不在历史文档保留另一套待办。
