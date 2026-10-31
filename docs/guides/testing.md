# 测试与验收

本文集中维护检查命令、最近验证证据与验收清单。功能完成度见 [实施状态](../status.md)，逐轮记录见 [验证历史](../history/validation-2026-10.md)。历史测试数量不保证与未来检出一致。

## 测试分工

| 位置 | 用途 | 执行方式 |
| --- | --- | --- |
| `test/` | 单元 / Widget 回归，数据库使用真实 SQLite，窗口与播放交互使用假实现 | `fvm flutter test` |
| `integration_test/` | 使用正式 runner 的真实窗口 / 播放冒烟应用 | `fvm flutter run -d <平台> -t integration_test/windowing_smoke.dart` |
| `tool/check_architecture.dart` | 中文文件说明、界面归属、引用与依赖方向 | `fvm dart run tool/check_architecture.dart` |
| `tool/check_l10n.dart` | ARB key、非空文案和必需占位符检查 | `fvm dart run tool/check_l10n.dart` |

`integration_test/` 当前不是 Flutter integration_test 框架套件，不会随普通 `flutter test` 自动运行。`video_fixture.dart` 在临时目录生成视频，避免下载素材或提交二进制资产。`tool/` 是开发工具目录，不是产品运行代码。

## 用例维护规则

- 每个 `*_test.dart` 必须使用 `test()` / `testWidgets()` 注册命名用例；不能只在 main 中调用函数并手动抛错。表驱动的不同输入应有可辨识的用例名，支持单独筛选和故障定位。
- 断言使用 expect / expectLater。辅助代码只保留实际用于构造环境、控制异步或独立校验生产结果的部分；避免为了测试辅助函数而维护与生产路径脱节的第二份实现。
- 合并重复断言时，先明确行为由哪个生产路径的测试接管。相同测试名称、不同组件或不同失败边界不自动构成重复。
- 历史 schema 和故障回归按当前兼容约定保留；生成夹具由工具维护，不按文件时间删除。原生冒烟单列，不计入普通测试通过数量。

本轮清理依据见 [测试整理记录](../history/test-cleanup-2026-10-31.md)。432 项包含此前未注册的解析和搜索计划场景；不能将数量增长理解为新增了同等数量的功能覆盖。

## 推荐运行顺序

使用 [.fvmrc](../../.fvmrc) 固定 SDK；首次检出或资源变化后执行：

```bash
fvm flutter pub get
fvm dart run tool/check_l10n.dart
fvm dart run tool/check_architecture.dart
fvm flutter gen-l10n
fvm flutter analyze --no-fatal-infos
fvm flutter test
```

按需筛选和格式化：

```bash
fvm flutter test test/features/playback
fvm flutter test --plain-name "解析"
fvm dart format lib test tool integration_test
```

SDK 旧 Material/Cupertino 导入的 info 弃用提示暂不导致失败，错误和警告仍导致静态检查失败。格式为 120 列，由 `analysis_options.yaml` 指定；平台 / 构建目录不参与 Dart 静态分析，drift 生成代码参与分析。Windows CI 已按相同目录执行格式检查，使用固定 SDK；生成代码继续由工具生成，不手工修改。

## 测试宿主与真实窗口

[test/flutter_test_config.dart](../../test/flutter_test_config.dart) 在普通测试套件开始、创建 binding 之前关闭测试进程内的实验窗口能力。正式应用和冒烟入口继续采用项目 `enable-windowing=true`；涉及窗口操作的普通测试注入 `WindowService` 假实现。

固定 SDK `5ba8961b51` 先在 WidgetsBinding 初始化平台窗口宿主，再由 flutter_test 安装测试窗口宿主。Windows flutter_tester 不提供 `InternalFlutterWindows_WindowManager_Initialize`，原生初始化会导致测试加载失败。此配置隔离宿主能力，不跳过测试、不修改 SDK、不关闭产品多窗口。升级 SDK 后应复查是否可移除此配置。

## 验证基线

以下按实际执行日期记录最近验证证据，文档整理日期不作为测试执行日期。2026-10-31 的 Dart 回归与静态检查来自当前统一职责目录、DO / 业务模型 / VO 分离和显式依赖契约的工作区；原生冒烟仍为 2026-10-26 的记录，此前 SMB 接入对应提交 `d23458b`。不同日期、平台和样片的结论不可互相替代。

| 验证项 | 记录日期 / 结果 | 覆盖与限制 |
| --- | --- | --- |
| macOS 全量 Dart 回归 | 2026-10-31，432 项通过 | 包含来源表单保存 / 取消 / 迟到连接回收、列表批量查询次数 / 分页 / 刷新回归、媒体库编排互斥 / 退出、连接收尾、失败批次 / 部分结果统计、元数据事务回滚 / 并发导入去重、TMDB 请求错误分类、失败保留原关联、季级隔离与重试、连接提示；以及会话资源顺序、引擎 / 打开 / 关闭失败、并发换片、进度隔离及窗口创建失败，字幕自动 / 手动选择、轨道事件乱序、换片重置 / 迟到结果隔离与关闭；来源变更通知、设置生效后的趋势刷新及进度条交互；新增六类 DO 映射、schema 2 原库兼容、详情 VO 快照、主题保存失败 / 销毁、主题 / 语言读取竞争、设置销毁后的加载 / 保存、开始退出后忽略迟到读取及保存排空、插件 false 返回值重试及 TMDB API 候选顺序回归；不代表真实 NAS 或大库性能 |
| 格式 / 静态检查 / 文案 | 2026-10-31，格式通过；无错误 / 警告；280 条文案检查通过 | 保留 SDK 旧 UI 导入弃用 info；不代表完整页面人工验收 |
| 架构与中文说明检查 | 2026-10-31，317 个手写 Dart 文件通过；违规样例验证见下文 | 检查中文文件说明、功能 UI 归属、引用有效性、模型映射分离、数据 / 核心依赖方向及功能循环依赖；不等同于业务职责的自动语义审查 |
| macOS Release SMB HTTP 冒烟 | 2026-10-26，两个成功标记均输出 | 会话管理真实 media_kit 的打开与释放，前后及快速 seek；读取器为带延迟的替身，不连接 NAS |
| macOS Release 多窗口冒烟 | 2026-10-26，成功标记输出 | 创建 / 替换 / 关闭重开、全屏、共享状态及最终进度持久化；不代替原生关闭按钮或长期使用 |
| Windows Debug / Release 与多窗口冒烟 | 2026-10-17–18 的记录通过 | 旧阶段正式入口构建、纹理、双视图与退出；不证明当前 SMB 代码或手工输入 / DPI 通过 |
| Windows 原生最小尺寸冒烟 | 2026-10-18，成功标记输出 | WM_GETMINMAXINFO、mini 约束切换、视图隔离与重开；真实鼠标拖动 / DPI 仍需验收 |
| macOS 原生最小尺寸专项 | 尚无专项成功记录 | 播放冒烟不等于内容约束或手动缩放已验收 |
| 文件对话框人工确认 | 2026-10-14，人工验收反馈确认通过 | 未逐项列出平台和边界，不能推广为 Windows 全部用例通过 |

历史测试数量、CI 链接、标题栏检查与排障过程保留在 [验证历史](../history/validation-2026-10.md)，不在此累积逐轮流水账。

## 自动化覆盖索引

| 领域 | 主要位置 | 关注点 |
| --- | --- | --- |
| 数据层 | `test/core/data/database/` | 组合唯一键、外键 / CHECK、JSON、日期、事务、局部更新、级联 / 禁止删除、开发库并发重建、双后台连接、关闭重开 |
| TMDB 与刮削 | `test/core/data/tmdb/tmdb_api_test.dart`、`test/features/library/metadata/application/`、`library_sync_integration_test.dart` | 401 / 403、429 / Retry-After、超时 / 连接 / 取消 / 5xx、异常响应、列表接口 404 与详情资源 404、真正空结果；失败不回退或清除匹配、季级隔离、重新扫描与错误提示；使用请求替身和真实 SQLite，不请求真实 TMDB |
| 库查询 | `test/features/library/catalog/data/library_catalog_repository_impl_test.dart` | 标题可用性、搜索 / 收藏 / 续播排序、有限结果、SQL 与领域规则一致性、共享订阅 |
| 列表查询开销 | `test/features/library/catalog/data/library_catalog_repository_impl_query_test.dart` | 真实 SQLite 拦截 SELECT：100 条电影 / 剧集混合收藏或续播由 101 次降为 3 次；验证分页顺序、类型隔离、图片 / 评分、未匹配回退、元数据变更刷新及 400 个 ID 的分批边界；不等同于端到端耗时或大库容量基线 |
| 存储 | `test/core/data/storage/` | 路径、凭据、浏览 / 扫描适配；SMB 假客户端不代表真实 NAS 连接通过 |
| 同步编排 | `test/features/library/sync/application/library_sync_service_test.dart` | 不使用 SQLite / TMDB / 协议实例的行为测试：互斥、批次、部分扫描、失败隔离、写入失败不重试、关闭计数 / 已入库数量保留、退出等待、迟到连接与路径查询期间退出 |
| 媒体库适配 | `test/features/library/metadata/data/metadata_repository_impl_test.dart`、`storage_library_source_scanner_test.dart`、`tmdb_metadata_source_test.dart` | 真实 SQLite 验证原子回滚；凭据 / 来源过滤、连接幂等关闭、失败完整性标记及后端错误转换 |
| 媒体源应用入口 | `test/features/library/sources/application/storage_sources_service_test.dart`、`test/features/library/sources/ui/source_dialogs_test.dart`、`test/features/library/browser/application/file_browser_provider_test.dart` | 临时连接释放、接受任务收尾、退出拒绝新操作、来源删除通知、表单保存与取消、保存失败不影响浏览、保存 / 删除后的浏览失效、等待凭据 / 建连期间变更来源及迟到连接关闭 |
| 应用组装 | `test/app/bootstrap/` | 共享 TMDB / 数据库、独立实例；不挂载页面时的设置刷新与来源浏览失效；窗口创建失败时释放已准备会话且不创建引擎 |
| 应用退出 | `test/app/application/` | 重复请求、保存 / 释放顺序、失败与超时、最终快照持久化 |
| 播放 | `test/features/playback/` | 会话拥有引擎 / 目标；打开 / stop 失败、重复 / 竞争关闭、迟到解析回收、换片中禁止进度串写；门面、轨道 / 字幕、seek 与 mini / 全屏 |
| 字幕交互 | `test/features/playback/ui/controllers/player_subtitle_controller_test.dart`、`playback_engine_boundary_test.dart` | 语言优先级、手动选择保留、先选轨后到列表、外挂身份 / 去重、换片清空但保留样式、旧请求迟到成功 / 失败隔离、关闭拒绝新交互且不释放借用引擎 |
| 媒体库状态恢复 | `test/features/library/application/media_library_provider_test.dart` | 初始化失败重试、并发加载合并、多个订阅独立恢复、重试取消旧订阅、首条错误 / 空流、不可修改列表快照、等待首条数据期间退出 |
| 设置与趋势联动 | `test/features/settings/application/app_settings_provider_test.dart`、`test/features/home/application/trending_media_provider_test.dart` | 初次加载 / 草稿 / 配置未变不重复刷新；持久化失败不应用配置，退出不启动刷新；普通加载合并，配置变化合并重刷，旧成功 / 失败结果隔离，移除配置清空，销毁后不通知 |
| 播放进度条 | `test/features/playback/ui/widgets/player_seek_bar_test.dart` | 初始位置 / 缓冲快照、悬浮预览复用 / 移除、拖动期间保留选择且释放时 seek、引擎替换后重绑订阅并清理预览；组件不释放借用引擎 |
| 本地化 | `test/l10n/` | 三种偏好、保存失败重试、ICU 与格式化、语言切换不重建会话 |
| SMB 回源 | `test/core/data/storage/smb_http_playback_proxy_test.dart`、`smb_playback_resolver_test.dart` | HEAD / Range、令牌 / Host / 路径、并发 / 取消、快速 seek 的最新请求不被 503 拒绝、读取失败与幂等关闭；不连接真实 NAS |
| 表单布局 | `test/core/ui/components/app_form_item_test.dart` | 窄弹窗、中英文、字号放大、说明换行、连接结果与按钮对齐 |
| 视图消息 | `test/core/ui/components/app_message_test.dart` | 两视图独立队列，销毁一个宿主不影响另一个 |

表变化需重新生成代码、增加版本与迁移测试，见 [数据模型](../architecture/data-model.md)。文件名解析与搜索计划测试分别位于 `test/features/library/sync/` 和 `metadata/`，与维护流程镜像。

## 原生冒烟

这些入口使用正式 runner，不随 `flutter test` 执行。平台构建应串行，避免争用同一构建目录；无需复制 SDK 或应用包。临时视频、SQLite 与偏好均隔离于用户媒体库，不请求 TMDB。

### 多窗口与播放

```bash
fvm flutter run -d macos --release -t integration_test/windowing_smoke.dart
fvm flutter run -d windows --release -t integration_test/windowing_smoke.dart
```

入口生成十秒 160×90 RGB AVI，验证双视图、共享语言、按 viewId 置顶 / 尺寸、全屏、替换复用、关闭重开、进度订阅与 SQLite 关闭重开后的快照。成功标记为 `WINDOWING SMOKE COMPLETE`。

退出由程序内回调触发，不覆盖真实关闭按钮、Cmd+Q / Dock。迁移期间出现过 frame-time clamping 日志；短片通过不能推断长期稳定或没有资源泄漏。

### SMB HTTP 与快速 seek

```bash
fvm flutter run -d macos --release -t integration_test/smb_http_playback_smoke.dart
fvm flutter run -d windows --release -t integration_test/smb_http_playback_smoke.dart
```

使用 40 秒 RGB AVI 和每块 30ms 读取延迟的替身，由正式播放会话持有回源目标与 media_kit 引擎，并通过会话关闭接口检查释放。每轮以 15ms 间隔发出 8 次 seek，连续 3 轮后继续跳转，检查最后目标可到达、后续 seek 有效、源只关闭一次。成功必须同时输出：

- `SMB HTTP RAPID SEEK PASS`
- `SMB HTTP PLAYBACK SMOKE COMPLETE`

它验证 HTTP 与播放器及 Release 沙箱监听，不验证真实 SMB 认证、网络重连或高码率表现。请求丢弃与 503 的复现过程见验证历史，协议和取消机制见 [播放架构](../architecture/playback.md#smb-http-回源)。

### 原生窗口尺寸

```bash
fvm flutter run -d macos --release -t integration_test/window_constraints_smoke.dart
fvm flutter run -d windows --release -t integration_test/window_constraints_smoke.dart
```

查询原生内容缩放限制，检查主窗口 / 播放器 / mini、窗口隔离与关闭重开。成功标记为 `WINDOW CONSTRAINTS SMOKE COMPLETE`；正式通过的平台以验证基线为准，手动拖动和多显示器仍需另测。

冒烟失败会打印异常。不要只凭 CLI 退出码判断；应用自行退出后 CLI 可能仍等待，看到完整成功标记后可结束 CLI。

## 手工验收清单

各平台分别记录应用提交、SDK 提交、系统版本、媒体样片和结果；失败附步骤与脱敏日志。SMB 另记录 NAS / SMB 版本、认证方式、文件大小 / 码率；不记录密码或会话令牌。未记录用例视为未确认。

| 场景 | 操作 | 通过标准 |
| --- | --- | --- |
| 基本窗口 | 播放、聚焦、拖动 / 最小化 / 恢复、中英文输入、复制粘贴 | 主窗口持续响应，输入归属正确，无额外播放器 |
| 单独关闭 | 播放后关闭播放器，重开同一媒体 | 主窗口可操作，续播位置存在，无残留声音 / 窗口 |
| 主窗口退出 | 无播放器 / 播放中关闭主窗口；macOS 另测 Cmd+Q / 菜单 / Dock | 所有窗口 / 音频结束，进程退出，重启有最终进度 |
| mini / 全屏 | 切换 mini、置顶与全屏，分别重复两种关闭方式 | 原尺寸 / 约束 / 置顶恢复，界面状态符合实际窗口状态 |
| 竞争与失败 | 连续启动 / 换片 / 关闭，全屏转换中关闭，注入写入 / 释放超时 | 不重复播放、不残留窗口，失败有界且不伪称保存成功 |
| 对话框 | 添加 / 编辑目录，选取 / 取消字幕，中文路径、过滤、全屏下操作及父窗口关闭 | 绑定正确父窗口，失败有提示，不影响另一视图 |
| 真实媒体 | 本地 / WebDAV seek、切集、音轨、内嵌 / 外挂字幕、倍速、样式覆盖 | 音画、时间与轨道状态符合内容 |
| SMB / NAS | 打开、续播、连续快速 seek、接近末尾跳转、换片 / 换来源、断网再恢复、反复关闭 / 重开 | 最新跳转仍有效，错误可见且可退出，重新打开可恢复；无残留监听或 worker，记录高码率缓冲与 seek 延迟 |
| 解码与画质 | 各编码、软 / 硬解、HDR 样片，观察资源与日志 | 逐样片记录，不以 RGB AVI 或假引擎替代 |
| 语言与布局 | 三种偏好、重启、播放 / 换片中切换、英文长文案、已有弹层 | 双视图一致、不重开媒体，格式 / 复数正确，无溢出 |
| 边界与发布 | 多显示器 / DPI、跨 Spaces、遮挡 / 后台、长时间播放、键盘 / VoiceOver、安装启动 | 逐平台记录，构建与签名 / 公证分别确认 |

SMB 浏览 / 超时与转发播放分别验证；当前缺口见 [实施状态](../status.md)。Emby 与系统 PiP 不属于现有功能验收范围。

## CI 与后续验证

[Windows 工作流](../../.github/workflows/windows.yml) 与 [macOS 工作流](../../.github/workflows/macos.yml) 使用相同 `.fvmrc`，执行依赖安装、文案 / 架构 / 格式检查、本地化生成、静态分析、全量测试及对应平台 Release 构建。产物保留 14 天；macOS 应用先归档，以保留权限和符号链接。普通测试通过 [flutter_test_config.dart](../../test/flutter_test_config.dart) 隔离原生宿主初始化；正式应用仍启用多视图。

合并门禁使用固定检查名称 `Test and build Windows`、`Test and build macOS`。应在真实 PR 运行两个检查后，将 master 设为需要 PR、两个状态检查通过且分支保持最新；不强制要求第二位开发者批准，避免单人维护时无法完成自身变更。现有规则必须先检查后调整，配置文件本身不能证明仓库门禁已经启用。

本轮本地 macOS Release 构建成功，并验证归档中的主程序执行权限及 90 个框架符号链接保留。云端双平台结果与仓库实际门禁配置需在提交到 GitHub 后核对；本地构建不能代替 Windows 或 macOS runner 的成功结果。

容量基线、可重复的真实媒体样片与人工结果仍需完善。功能阶段更新 `status.md`，本指南只更新最近证据；旧记录移入历史，避免多处维护不同的测试数量。

## 边界与旧库验证

`test/core/data/database/mappers/` 验证数据库字段、枚举与 JSON 映射完整性；`schema_v2_compatibility_test.dart` 用已提交的 schema 2 快照建库后打开当前数据库，验证结构、原数据与局部更新。`test/generated/schema/` 由 `fvm dart run drift_dev schema generate drift_schemas test/generated/schema` 生成，保留历史结构作为兼容证据，不手工编辑。

架构检查接入 Windows CI；本地负例覆盖中文文件说明、Provider 依赖具体实现、领域序列化、数据库复用业务行、VO 混入 Mapper、错误 UI 归属、core 反向引用与功能循环依赖，均须拒绝。检查通过不替代人工职责审查。
