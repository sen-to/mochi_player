# 0001 多窗口策略：官方单引擎多视图，主窗口关闭即退出应用

- **Status**: Accepted（2026-10-14 完成迁移主体；Windows 运行时仍待验收）
- **Date**: 2026-10-13（初稿 2026-10-05）
- **Related**: [0002 播放引擎](0002-playback-engine.md)、[0003 持久化](0003-persistence-migration.md)、[0004 l10n](0004-i18n-l10n.md)、[历史原型验证](../experiments/official-single-engine-windowing.md)

## Context（背景与约束）

- 保留媒体库主窗口和独立播放器；同一时间只有一个播放器窗口。最小化不等于关闭。
- **关闭主窗口必须保存最后进度、关闭播放器并退出整个程序。** 单独关闭播放器只结束播放，主窗口继续运行。
- 旧实现采用 `desktop_multi_window`，每个窗口独立引擎、Provider 和数据库连接，需要语言快照与播放窗口 RPC。Windows 曾出现打开播放器后主窗口输入冻结；换后端不能直接视为该问题已解决。
- 2026-10-12～13 的 macOS 原型验证了基础窗口、media_kit 纹理、输入、关闭协调和 Release 独立运行。2026-10-13 用户明确要求正式迁移，取代此前「仅实验，不重构」的阶段限制。

## Decision（决策）

**采用 Flutter 官方实验窗口 API，在单个引擎和 UI isolate 中承载主视图与播放器视图；共享应用状态与数据库，按视图管理窗口操作。**

### SDK 与发布

- `.fvmrc` 固定本轮查询到的最新 main 提交 `5ba8961b517919e97cd58e404b75dcdcf313017a`，提交时间 2026-10-13 10:03:36 UTC。FVM 显示版本 `3.49.0-1.0.pre-447`、开发通道 `master`。团队和 CI 使用相同提交，不跟随浮动 `main` 自动升级。
- 官方 Dart 窗口 API 仍为实验能力。项目在 `pubspec.yaml` 设置 `flutter.config.enable-windowing=true`。历史 stable 3.47.2 有多视图底层接口，但该实验 API 的开关受通道可用性限制；不是追加 run 参数就能在 stable 获得同一 API。
- FVM 下载对应预编译引擎，不要求自行编译 Flutter 源码；开关不限定 Debug，Release 可以打包成独立应用。签名、公证与 Windows 发布仍需分别验收。
- 该提交中的 Material/Cupertino 旧导入已被标记弃用。本轮保留现有 UI 依赖，不引入新旧 UI 的兼容桥；静态检查使用 `--no-fatal-infos`，仍保留这些提示。独立 UI 包迁移需同时检查 go_router、gen-l10n 与插件，参见 [官方迁移说明](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui)。

### 窗口与状态所有权

- [DesktopWindowHost](../../lib/core/platform/desktop_window_service.dart) 使用 `WindowManager` / `WindowRegistry` 管理 `WindowEntry`；官方 internal API 只出现在这个生产适配文件。
- macOS 与 Windows runner 只创建一个 `FlutterEngine`，插件只注册一次。窗口由 Dart 创建；删除旧的隐式主窗口宿主、多引擎回调及旧窗口插件依赖。
- `WindowService` 通过每个视图的 Provider 注入，包含该视图的 `viewId`。不再用引擎全局 singleton 推断当前窗口。全屏、激活、尺寸约束使用官方控制器；位置、拖动、普通小窗置顶、文件 / 目录对话框和 macOS 按钮显隐通过原生桥按 `viewId` 定位。
- 主窗口与播放器共享 `AppLocaleController`、`ThemeProvider`、`AppSettingsProvider` 和 `DatabaseService`。窗口按钮状态、提示消息队列、播放器会话与播放资源由各自视图拥有。`AppMessage` 按调用方 context 找到所属视图的宿主，不保留引擎全局队列；播放器字幕错误不能投递到媒体库窗口。
- [PlayerWindowCoordinator](../../lib/features/playback/application/player_window_coordinator.dart) 由启动入口创建并通过 Provider 注入，串行创建、替换与关闭单个 `PlayerWindowSession`；不使用全局静态转发层。请求是内存中的 `PlayerWindowRequest`；保留文件引用与队列，移除版本化 JSON 协议、就绪轮询、跨窗口 RPC 和语言 revision 快照。
- 替换前解析下一目标；成功后先保存并释放旧播放资源，解绑旧页面一帧，再挂载新页面。解析失败保留原播放，不补偿创建第二个播放器。
- 删除播放器视图时先从 registry 注销，等待渲染帧移除 View，再 destroy / dispose 原生控制器。不能先销毁 FlutterView 再让旧组件继续绘制。
- macOS 全屏请求仍由官方控制器发出，但状态位可能在动画完成前更新。原生桥观察 AppKit 的 will / did fullscreen 通知，最多等待 5 秒确认完成；下一请求不能在动画中途发送。失败后 UI 校准实际状态，退出失败保留恢复责任以便重试。
- 删除依赖隐式视图的 `file_selector`：已锁定的 Windows 插件通过 `registrar->GetView()` 找父窗口并直接解引用，单引擎新宿主不能保证该隐式视图存在。目录与字幕选择改为 viewId 对应的 AppKit sheet / Windows IFileOpenDialog；取消返回空值，失败由界面显示本地化提示。2026-10-14 用户确认文件对话框手工验收完成；Windows 平台与未逐项报告的边界用例仍按测试指南单独验证。

### 数据库与退出

两个视图使用同一个后台 drift + SQLite 连接，WAL、busy timeout、字段级更新和事务继续保留。播放器关闭不会关闭数据库；共享 drift 订阅直接接收同一连接的进度变更；删除旧的变更键集合、关闭回调与跨连接手动查询失效。

所有可拦截的主窗口关闭、平台退出和 macOS Cmd+Q 进入同一个幂等退出流程：

1. 拒绝新的播放 / 替换请求和后台任务，禁用主窗口交互。
2. 等待已接受的播放器操作收尾，保存最终进度、释放播放资源、解绑并销毁播放器视图。
3. 收尾媒体库任务和设置写入，最后关闭共享数据库并结束进程。

播放器会话收尾、进度、视图阶段各最多 2 秒；资源释放与窗口恢复最多 12 秒，覆盖进入 / 退出全屏各最多 5 秒的确认；应用退出的播放器阶段最多 18 秒，应用清理最多 8 秒，macOS 原生退出另有 30 秒兜底。超时记录失败并最终退出，不留下后台播放。超时 / 强杀不保证最后快照，但不伪称保存成功。单独关闭播放器复用相同资源清理流程，保留主窗口与数据库。

### 小窗：采用 mini 播放器

2026-10-14 决定继续采用 mini 播放器，暂不考虑 macOS / Windows 系统画中画。mini 使用同一个播放器窗口与播放会话，尺寸为 480×300、最小 420×260；默认置顶，可由用户切换，macOS 下隐藏系统窗口按钮。退出 mini 恢复原窗口尺寸、约束与置顶状态。

当前固定 SDK 的官方 Dart 窗口 API 未提供通用置顶方法，因此调用链为 `PlayerWindowModeController → WindowService → mochi_player/window_controls 原生通道 → 目标窗口`。每次请求携带 `viewId`，只修改对应播放器窗口，不根据当前焦点选择窗口，也不依赖旧的 `window_manager` 插件。

- macOS：设置 `NSWindow.level = .floating` 置顶，取消时设为 `.normal`。
- Windows：调用 `SetWindowPos`，通过 `HWND_TOPMOST` / `HWND_NOTOPMOST` 设置或取消置顶，并检查返回值。

进入 mini 前记录原置顶状态，退出时恢复该状态，而非无条件取消置顶。这里调用的是系统窗口层级接口，不属于系统画中画；macOS `.floating` 也不代表跨所有 Spaces 或其他应用全屏空间显示。

选择依据：项目面向本地 / 网络媒体库与剧集播放，小窗需要延续现有字幕、切集和播放控制，mini 更容易保持双平台体验一致。当前 media_kit/libmpv 渲染可直接复用；系统 PiP 会额外引入平台内容源、视频帧与字幕合成、播放控制和生命周期桥接的维护成本。

**mini 是普通播放器小窗，不是系统画中画。** 当前只提供 mini 入口，不新增 PiP 接口、视频帧桥接、原型或双方案自动回退；系统 PiP 不属于本次重构的交付与验收缺口。若未来产品需求变化，再单独评估并修订 ADR。

## 实施与验收

实施内容包括官方窗口宿主、视图级窗口服务、共享状态与数据库、直接会话调用和旧后端删除。macOS Debug / Release 构建与回归测试与隔离的真实播放 / SQLite 集成运行已通过。验证方式见 [测试指南](../guides/testing.md)。

仍需分别验收：

- Windows 编译、Debug / Release 运行、输入冻结回归、原生窗口扩展、多显示器与 DPI。
- 主窗口原生关闭按钮、播放器聚焦时 Cmd+Q、连续打开 / 替换 / 关闭；播放错误、长时间播放和无响应超时。
- 真实媒体 seek、切集、内嵌 / 外挂字幕、硬解、HDR 与可访问性；Windows 原生文件对话框及未逐项报告的对话框边界用例。
- 双平台签名 / 发布流程。

macOS 成功和单元测试不替代 Windows 运行时验收；历史原型结果也不替代正式业务验收。没有保留可自动回退的旧后端；如本轮发现阻塞缺陷，应在迁移分支修复或明确回退整个变更，不长期维护两套实现。

## Consequences（后果）

- 减少窗口间通信、重复状态加载和连接管理；保留独立播放器与明确退出语义。
- 引入 main SDK 与 internal API 的维护成本；单个 UI isolate 中阻塞操作会影响所有视图，应继续让数据库和重任务在后台执行。
- 原生扩展仍需双平台维护。实验 API 可打包不等于稳定版本承诺，也不等于所有插件已兼容多视图。

## Alternatives（备选）

| 备选 | 评价 |
| --- | --- |
| 保留多引擎插件 | 已被本轮迁移替代，不维护兼容 RPC |
| 取消独立播放器 | 不符合产品需求 |
| 自行创建原生多视图宿主，继续 stable | 可评估，但需自行承担窗口协议和适配工作；本轮用户选择官方 main API |
| 改为原生播放器 | 属于播放后端决策，不为窗口迁移同时替换 media_kit |

## Revisit trigger（重估触发条件）

1. 官方 API 在稳定通道开放，或出现不兼容变化：重新锁定 SDK 并执行双平台验收。
2. 目标平台存在阻塞主流程且无法修复的插件或窗口缺陷。
3. 小窗的产品需求发生变化，现有 mini 无法满足时，重新评估小窗方案。
4. 产品改为主窗口关闭后继续播放：必须重设计应用宿主与数据库生命周期。
