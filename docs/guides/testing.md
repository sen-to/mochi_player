# 测试与代码质量

## 现状

- 测试包含 SQLite 数据层与查询订阅测试，目录与 `lib/` 大体对应：
  - `test/core/**` —— 设计系统组件、存储解析器、TMDB 匹配与映射、格式化的单元与 Widget 测试；
  - `test/features/**` —— 媒体库查询、文件浏览、播放队列与进度写入、设置；
  - `test/app/**` —— 外壳组件、应用退出协调与退出时的 SQLite 持久化。
- 两个测试位于 `test/` 根目录（`filename_parser_test.dart`、`scrape_plan_test.dart`），与镜像结构不一致，属于待整理项。
- 数据层依赖注入到位：`DatabaseService`、`TmdbService`、存储扫描器等都可从构造函数替换，因此多数测试不触碰真实数据库或网络。

## 运行

```bash
fvm dart run tool/check_l10n.dart              # 文案完整性
fvm flutter gen-l10n                          # 生成本地化代码
fvm flutter test                              # 全部
fvm flutter test test/features/playback       # 指定目录
fvm flutter test --plain-name "解析"          # 按名称筛选
fvm dart format lib test tool integration_test # 格式化（120 列，配置见 analysis_options.yaml）
fvm flutter analyze --no-fatal-infos            # 静态检查（保留 SDK 弃用提示）
```

提交流程至少运行全量测试、格式化和静态检查；目录与名称筛选命令是按需使用的示例。CI 执行文案完整性检查、本地化生成、analyze、test 和 Windows 构建。

### 测试宿主与真实窗口

`test/flutter_test_config.dart` 在每个测试套件启动、创建 binding 之前关闭测试进程内的实验窗口能力。`test/` 中的单元 / Widget 测试使用注入的 `WindowService` 假实现，不创建真实原生窗口；正式应用和 `integration_test/windowing_smoke.dart` 继续使用项目的 `enable-windowing=true`。

固定 SDK `5ba8961b51` 的 `WidgetsBinding.initInstances` 会先创建平台窗口宿主，随后 `flutter_test` 才安装测试窗口宿主。在 Windows 的 `flutter_tester` 中，前一步找不到 `InternalFlutterWindows_WindowManager_Initialize`，导致测试文件加载失败。测试配置隔离该原生初始化，不跳过测试、不修改 SDK，也不关闭应用的多窗口能力。该测试配置只作用于 `test/`，真实窗口、输入与退出仍需通过正式 runner 的集成 / 人工验收。升级 SDK 后应复查是否可移除此配置。

## 约定

- 代码统一 120 列，由 [analysis_options.yaml](../../analysis_options.yaml) 的 `formatter.page_width` 声明，无需传参。
- 导入统一使用包路径（`always_use_package_imports`）。
- 构建与平台目录（`build/**`、`windows/**`、`macos/**`）不参与静态检查；drift 生成代码参与静态检查。

## 待补

| 项 | 说明 |
| --- | --- |
| 格式检查未进 CI | 建议增加 `dart format --set-exit-if-changed`，避免格式化差异混入评审 |
| 无 macOS CI | macOS 是主要开发平台，但流水线只有 Windows；至少应跑 analyze 与 test |
| 缺验收清单 | [0002](../decisions/0002-playback-engine.md) 的播放能力表尚未落成可执行的手工验收步骤（HDR、多音轨、字幕样式等难以自动化） |

## SQLite 数据层

`test/core/infrastructure/database/database_service_test.dart` 使用真实 SQLite 验证唯一键更新、JSON 元数据往返、日期精度、事务回滚、播放进度与收藏的局部写入、来源删除和清理语义。临时文件测试验证两个后台连接的并发写入与关闭后重开。

`test/features/library/application/library_repository_test.dart` 验证 SQL 可用性筛选、分页、Unicode 搜索排序、剧集详情范围、队列、收藏去重、续播与领域策略一致性、订阅失效和刮削候选。旧 Catalog 查询测试和 Entity 映射测试已移除。

修改表定义后执行 `fvm dart run build_runner build`。schema 版本从 1 开始，尚未发布 Release，因此不提供 Isar 旧数据导入；后续 SQLite schema 变更需提升版本并提供版本间迁移测试。

## 窗口退出回归

`test/app/application/` 覆盖退出顺序、重复请求、播放器 / 主窗口清理失败与超时，以及排队周期保存和最终快照在 SQLite 关闭重开后的持久化。`player_window_coordinator_test.dart` 覆盖串行创建 / 替换、启动或替换期间退出、关闭重开和失败请求后重试；`player_window_close_coordinator_test.dart` 验证保存 / 释放结果确认及失败后继续清理。播放会话与设置测试补充切集期间退出、等待已接受保存并拒绝新保存。

手工验收在 macOS / Windows 分别执行：

1. 无播放器时关闭主窗口，确认窗口消失且进程结束；macOS 另测菜单退出、Cmd+Q 与 Dock 退出。
2. 播放后单独关闭播放器，确认最后进度保存，主窗口继续可操作并可再次启动播放器。
3. 播放过程中关闭主窗口，确认最后进度保存、全部窗口关闭，进程结束；重新启动检查续播位置。
4. 在 mini、置顶、全屏状态分别重复第 2、3 项。
5. 连续点击关闭、启动 / 切集期间退出，确认没有残留窗口或重复播放。
6. 模拟子窗口或写入无响应，确认退出有界；查看失败阶段日志，不把超时退出当作最后快照成功保存。

构建和单元测试不替代视频渲染、原生窗口及进程退出的手工验收。

2026-10-11 验证记录：`flutter analyze` 无问题，全部 186 项测试通过，macOS Debug 构建成功。macOS 使用临时检查入口、隔离 SQLite 和模拟播放资源验证了原生双窗口 / RPC：子窗口独立关闭并重新创建、带子窗口关闭主窗口、子窗口聚焦时 Cmd+Q；记录确认最终进度写入后才释放资源、关闭子数据库，随后关闭主数据库并结束进程。临时入口不随项目交付。真实视频 mini / 全屏、Windows 原生运行时及无响应注入仍待验收。

## 播放引擎门面回归

`playback_engine_boundary_test.dart` 注入 `FakePlaybackEngine`，验证打开媒体时的目标 / 认证头和类型明确的设置、轨道事件及音频元数据、外挂字幕加载与再次选择、字幕关闭 / 样式覆盖、控制栏播放与 seek，以及退出时暂停 → 最终保存 → 释放的顺序与重复释放。原有外挂字幕路径和日志脱敏测试改为使用项目类型，不依赖 media_kit。

2026-10-12：全部 190 项测试通过，`flutter analyze` 无问题，macOS Debug 构建成功。假引擎回归验证门面与业务 / UI 的交互，不替代后端参数效果、真实视频渲染、硬解和 Windows 运行时验收；能力基线与维护风险见 [ADR 0002](../decisions/0002-playback-engine.md)。

## 本地化回归

干净检出和修改 ARB 后，先执行 `fvm flutter pub get`、`fvm dart run tool/check_l10n.dart`、`fvm flutter gen-l10n`，再执行 analyze / test / build。生成目录 `lib/l10n/generated/` 被忽略；模板缺译、未知 key 或缺少占位符会使检查失败。

`test/l10n/` 验证系统语言回退、三种偏好、持久化 / 重启、快速切换、共享观察、退出收尾、语言选择控件、英文 Material 文案、日期 / 数字格式与单复数、结构化错误提示、语言切换不重新挂载会话。官方多视图集成入口检查两个 MaterialApp 观察同一个语言控制器。既有 Widget 测试显式配置中文及委托，避免依赖执行机器的系统语言。

2026-10-12 本轮验证：275 条中英文文案完整性检查通过，删除生成目录后重新生成成功；`flutter analyze` 无问题，全部 201 项测试通过，macOS Debug 构建成功。生成代码未纳入 Git。

同日收尾修复：占位符改为语义名称，计数使用整数与 locale 数字格式，目录连接 / 删除 / 扫描提示补齐英文复数规则，扫描结果的连接标点交给 ARB。语言偏好区分当前选择与已成功保存的值，保存失败后可重试同一选择，且不会重复广播。回归新增保存失败重试和计数边界测试；277 条文案检查通过，静态检查无问题，全部 203 项测试通过。

手工验收按 [ADR 0004](../decisions/0004-i18n-l10n.md) 的回归基线执行；特别检查真实播放不中断、进度不重置、已有弹层与长英文布局、系统语言变化及 macOS / Windows 原生交互。当前 UI 自动验收工具无法绑定改名后的 macOS 应用，完整页面与原生双窗口验收仍待完成。

## 官方单引擎多视图迁移（2026-10-13）

SDK 固定到 `.fvmrc` 的 main 提交 `5ba8961b517919e97cd58e404b75dcdcf313017a`，项目级 `enable-windowing=true`。旧窗口插件、RPC、JSON 启动协议与语言快照已删除。`flutter analyze --no-fatal-infos` 仍打印 SDK 旧 Material/Cupertino 导入的弃用提示；错误和警告仍作为失败。独立 UI 包迁移单独处理，不通过兼容桥隐藏提示。

真实窗口 / 播放集成入口可以重复运行：

```bash
fvm flutter run -d macos -t integration_test/windowing_smoke.dart
# Windows 验收机器上执行：
fvm flutter run -d windows -t integration_test/windowing_smoke.dart
```

入口使用正式 runner、DesktopWindowHost 和 PlayerWindowApp，在自己的临时目录生成十秒 RGB AVI，使用隔离 SQLite 和内存偏好，不访问用户媒体库或 TMDB。无额外视频下载、二进制资产或证据 JSON。成功结束会删除临时数据并打印 `WINDOWING SMOKE COMPLETE`；失败打印异常与堆栈后结束进程。不要仅凭 flutter run 的退出码判定成功。

2026-10-13 macOS Debug 运行已验证：两个独立 FlutterView、共享语言渲染、按 viewId 的原生置顶与 480×300 尺寸、主窗口尺寸保持不变、官方全屏进出、请求替换复用视图、单独关闭保留主窗口与数据库、共享查询订阅接收进度、两次关闭重开，以及最终进度在 SQLite 关闭重开后存在。观察到 160×90 视频纹理分配与解码日志。底层仍偶发 `Reported frame time is older than the last one; clamping`，没有将其视为长期稳定性通过。

该入口对主窗口关闭事件处理器的测试是程序内回调，不替代真实红色关闭按钮、Cmd+Q / Dock 退出、拖动、最小化、焦点与中文输入的手工检查。Windows 全套运行时、真实片源 / 字幕 / HDR、长时间播放、多显示器、可访问性和发布签名仍待验收。

2026-10-13 自动化回归 198 项通过，277 条 l10n 文案检查通过；正式入口 macOS Debug 与 Release 构建成功。构建仍提示 media_kit 的 SPM 支持和上游 Swift 头文件警告；本项目保持 CocoaPods，未宣称这些上游问题已解决。

### 2026-10-14 恢复迁移后的验证

修正全屏动画完成确认。上轮最后一次运行的“全屏检查通过”结论不能直接沿用：固定等待一秒不可靠，状态位更新后立刻退出可能丢失请求。现在等待 AppKit 完成通知，单次确认最多 5 秒；窗口模式测试覆盖重复点击、进入过程中关闭、进入 / 退出失败后的重试。修正后的真实播放集成检查已完成整个退出与 SQLite 重开流程。

文件 / 目录选择不再依赖隐式视图插件。2026-10-14，用户确认文件对话框手工验收完成。该确认未逐项列出平台与边界用例；Windows 宿主、COM 对话框和 DPI 处理仍未确认编译或运行通过。后续目标平台回归清单包括：主窗口添加 / 编辑本地目录，播放器打开 / 取消外挂字幕对话框，中文路径、扩展名过滤、父窗口关闭和全屏下选择。

验证时串行执行平台构建，避免争用同一个 Xcode 构建目录。无需复制 SDK、应用包或保留整份构建备份。测试入口只生成临时小视频与 SQLite；验证后删除可重建缓存，保留应用产物、源码和当前 SDK。

2026-10-14：最终回归 204 项通过，277 条文案检查通过。资源释放 / 窗口恢复阶段改为最多 12 秒，覆盖正在进入全屏后再退出的动画确认；应用退出整体的 18 秒播放器阶段与 8 秒应用清理上限保留。资源无响应会记录失败并继续解绑视图，不无限等待。

2026-10-14 代码审查收尾：删除全局 `PlayerWindow` 转发层，协调器通过 Provider 注入；mini 切换捕获失败，进入失败尝试撤回部分修改，恢复成功后才清除原尺寸记录，失败后可重试。macOS 原生按钮操作成功后才提交 mini 按钮状态。新增五项故障回归，全量 209 项测试通过，静态检查无错误或警告，保留 108 条 SDK 旧 UI 导入弃用提示。Windows 桥检查尺寸 / 置顶等 Win32 调用结果并返回失败；本轮未执行 Windows 编译或运行验收。

2026-10-14 依赖升级：`dio 5.11.1`、`flutter_cache_manager 3.4.5`、`logger 2.8.0`、`shared_preferences 2.5.6`、`sqlite3 3.7.1`、`dart_smb2 0.1.3`；同步最低版本约束、Dart / CocoaPods 锁文件，`path` 改为 `^1.9.1`。SQLite 所需的 `hooks` 与 `record_use` 随依赖解析更新。全量 209 项测试（含真实 SQLite 与 SMB 适配测试）、277 条文案检查、本地化生成与 macOS Debug 构建通过；静态检查无错误或警告，108 条 SDK 弃用提示及 SPM 提示保留。真实 SMB 连接 / 超时与 Windows 原生运行未验收；SMB 客户端升级不代表 ADR 0005 中捆绑播放器的 `smb://` 打开 / seek 问题已解决。涉及独立 UI 包迁移的三个主版本升级另行处理。

共享连接的回归直接通过 `DatabasePlaybackMediaStore` 写入，检查媒体库 `watchVersions` 订阅收到新进度且保留收藏字段；不再依赖外部连接的手动失效函数。真实播放入口还验证共享 drift 订阅，以及通过正式播放控制栏进入全屏后从主窗口关闭事件处理器触发完整退出。

消息回归同时挂载两个宿主，验证主窗口与播放器消息隔离，以及播放器宿主销毁后主窗口仍能提示。提示调用必须提供所属视图的 context，纯数据服务继续使用错误码，不持有 UI context。
