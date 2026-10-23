# 测试与验收

本文提供运行方式、当前证据和手工步骤。功能完成度见 [实施状态](../status.md)，逐轮记录见 [验证历史](../history/validation-2026-10.md)。历史测试数量不保证与未来检出一致。

## 测试分工

| 位置 | 用途 | 执行方式 |
| --- | --- | --- |
| `test/` | 单元 / Widget 回归，数据库使用真实 SQLite，窗口与播放交互使用假实现 | `fvm flutter test` |
| `integration_test/` | 使用正式 runner 的真实窗口 / 播放冒烟应用 | `fvm flutter run -d <平台> -t integration_test/windowing_smoke.dart` |
| `tool/check_l10n.dart` | ARB key、非空文案和必需占位符检查 | `fvm dart run tool/check_l10n.dart` |

`integration_test/` 当前不是 Flutter integration_test 框架套件，不会随普通 `flutter test` 自动运行。`video_fixture.dart` 在临时目录生成视频，避免下载素材或提交二进制资产。`tool/` 是开发工具目录，不是产品运行代码。

## 推荐运行顺序

使用 [.fvmrc](../../.fvmrc) 固定 SDK；首次检出或资源变化后执行：

```bash
fvm flutter pub get
fvm dart run tool/check_l10n.dart
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

SDK 旧 Material/Cupertino 导入的 info 弃用提示暂不导致失败，错误和警告仍导致静态检查失败。格式为 120 列，由 `analysis_options.yaml` 指定；平台 / 构建目录不参与 Dart 静态分析，drift 生成代码参与分析。格式检查尚未进 CI，不表示可跳过本地格式化。

## 测试宿主与真实窗口

[test/flutter_test_config.dart](../../test/flutter_test_config.dart) 在普通测试套件开始、创建 binding 之前关闭测试进程内的实验窗口能力。正式应用和冒烟入口继续采用项目 `enable-windowing=true`；涉及窗口操作的普通测试注入 `WindowService` 假实现。

固定 SDK `5ba8961b51` 先在 WidgetsBinding 初始化平台窗口宿主，再由 flutter_test 安装测试窗口宿主。Windows flutter_tester 不提供 `InternalFlutterWindows_WindowManager_Initialize`，原生初始化会导致测试加载失败。此配置隔离宿主能力，不跳过测试、不修改 SDK、不关闭产品多窗口。升级 SDK 后应复查是否可移除此配置。

## 当前验证基线（2026-10-14）

| 验证 | 已记录结果 | 证据范围 |
| --- | --- | --- |
| macOS 全量 Dart 回归 | 职责分离后 227 项通过 | 数据库、查询、设置、播放 / 窗口协调、UI；新增临时连接成功 / 失败释放、退出拒绝 / 排空操作、迟到连接关闭、共享依赖、应用查询刷新与启动数据 / 关闭状态测试；不等于大库负载测试 |
| 文案检查与生成 | 277 条检查通过，gen-l10n 成功 | 不等于所有页面布局与原生菜单语言已验收 |
| macOS Debug / Release | 迁移期间构建通过，依赖升级后 Debug 构建通过 | 不等于签名 / 公证或所有旧产物反映最新源码 |
| macOS 原生播放冒烟 | 职责分离后重新通过；末尾输出 `WINDOWING SMOKE COMPLETE` | 新工厂创建 / 替换播放器、共享语言、置顶与 mini 尺寸、全屏、反复关闭重开、最终进度落库 / SQLite 重开；RGB AVI 与隔离数据，主窗口关闭由程序内回调触发，不是手工覆盖所有媒体 |
| Windows 自动测试 | [第二次 CI](https://github.com/sen-to/mochi_player/actions/runs/38509922678/job/115675829212) 静态检查与 209 项测试通过 | 同次原生构建失败，后续单独修复 |
| Windows CI 最终结果 | 修复宏冲突后，用户确认 CI 成功 | 确认构建通过；未记录成功运行链接，不代替运行时验收 |
| 文件对话框 | 用户确认手工验收完成 | 未逐项列出平台 / 边界，不能推广为 Windows 全套对话框验收 |
| 标题栏方法重命名 | 3 项通道测试、Swift 语法检查通过 | 统一为 configureTitlebar，不证明原生页面视觉效果 |

自动化不替代真实媒体、原生窗口、进程退出和发布验证。Windows 运行时、长时间播放、多显示器 / DPI、硬解、HDR、可访问性和发布仍待验收；系统 PiP 不在范围内。

## 回归覆盖索引

### SMB HTTP 播放回源（2026-10-23）

`test/core/infrastructure/storage/smb_http_playback_proxy_test.dart` 使用真实本机 HTTP 请求和内存 SMB 读取替身，验证 HEAD / GET、单段 / 开放结束 / 后缀 Range、越界 416、无效 / 多段 Range 回退、If-Range 回退、空文件、短读与分块、令牌 / Host / 路径校验、并发偏移及请求上限、读取失败和关闭中断。解析器测试确认凭据只交给读取器，URL 不含 SMB 主机和密码，目标重复释放只关闭一次。

播放会话测试覆盖引擎换片前保留旧目标、换片后与退出时释放、退出后迟到结果释放，以及解析失败保持原会话；日志测试确认回源令牌被脱敏。提交前审查还补齐新媒体打开失败时旧目标立即释放的回归，避免反复换片失败积累连接。上述测试不连接真实 SMB 服务，不证明 NAS 协议与网络性能。

首次接入全量 Dart 回归 258 项通过；后续快速 seek 修复结果见下文。静态检查仅保留固定 SDK 的 Material / Cupertino 导入弃用 info。

快速 seek 回归复现过旧实现的缺陷：在源读取阻塞期间连续中断 8 个 Range 请求，最新请求收到 503 而非 206。现改为限制 4 个活动传输、让最新请求替换最旧传输，并在 SMB 读取出队前检查取消状态；该测试要求最新范围仍返回正确字节，旧任务不会占位阻断新请求。`HttpResponse.done` 不保证在下一次写入前就发现客户端已经断开，不能只依赖它回收名额。

修复及提交前审查后全量 260 项测试通过，静态检查无错误或警告；macOS Release 已输出 `SMB HTTP RAPID SEEK PASS` 和 `SMB HTTP PLAYBACK SMOKE COMPLETE`。仍需在用户报告问题的真实 NAS / MP4 上重试，不能将隔离冒烟视为该媒体文件已经验收。

原生冒烟使用正式 runner、media_kit / libmpv 和临时生成的 RGB AVI，读取替身经正式 HTTP 转发服务提供视频，不访问用户数据库或凭据：

```bash
fvm flutter run -d macos --release -t integration_test/smb_http_playback_smoke.dart
# Windows 待验收：
fvm flutter run -d windows --release -t integration_test/smb_http_playback_smoke.dart
```

2026-10-23 首次 macOS Release 已输出 `SMB HTTP PLAYBACK SMOKE COMPLETE`，验证沙箱内监听、视频开始播放、向前 / 向后 seek、关闭引擎后释放目标与读取器。快速 seek 补充入口使用 40 秒视频和每块 30ms 读取延迟，每轮间隔 15ms 发出 8 次 seek，连续 3 轮后继续跳转；成功时另输出 `SMB HTTP RAPID SEEK PASS`。CLI 在应用自行退出后可能仍保持运行，看到成功标记后可结束 CLI。此证据不覆盖真实 SMB 连接、重连、Windows 或高码率视频。

同次原有 `windowing_smoke.dart` 的 macOS Release 回归也输出 `WINDOWING SMOKE COMPLETE`，覆盖替换播放器、关闭重开、全屏退出和最终进度落库，检查目标资源所有权接入后的窗口生命周期回归。

真实 NAS 手工验收应补充以下记录：

- 记录操作系统、NAS / SMB 服务端版本、认证方式与样片大小 / 码率；不要记录密码或完整会话令牌。
- 从 SMB 媒体源打开视频，前后多次拖动、接近末尾跳转，再关闭 / 重开确认续播；切换队列与更换来源后确认新文件播放正常。
- 播放中断开再恢复网络，确认错误可见、可关闭，重新打开可恢复；高码率样片记录缓冲与 seek 延迟。
- 单独关闭播放器后主窗口正常；重复打开 / 关闭及关闭主窗口退出，不残留监听端口或 SMB worker。
- macOS Debug / Release 与 Windows 分别验收，不能将本机 HTTP 冒烟推广为真实 NAS 全平台通过。

### 媒体源连接结果布局

媒体源启用开关复用 `SettingsSwitchItem`：开关保留自身宽度，标题和说明使用剩余空间。共享表单辅助说明允许换行，行高按内容增长；本地目录路径显示在整行下方。表单 Widget 测试覆盖 300 逻辑像素宽度下中英文启用说明、普通及 1.5 倍字号的文字边界，检查说明不被省略且不与开关重叠。

本地目录、SMB 与 WebDAV 固定显示“连接测试”标题，测试后在标题下方显示绿色“连接成功”或红色失败详情，不展示目录项数；未测试或测试中不显示结果。右侧按钮按内容宽度居中对齐，左侧使用剩余空间，长结果自动换行并撑高表单行。`test/core/ui/components/app_form_item_test.dart` 覆盖窄弹窗和放大字号下标题、结果及按钮的位置，以及长说明不省略的行为。WebDAV 端口必填：测试和保存都应拒绝空值、非整数及 1–65535 以外的值；编辑使用协议默认端口的地址时应显示实际端口。真实协议连通性另按媒体源手工清单验收。

### 桌面最小窗口尺寸（2026-10-18）

macOS 补充：用户同时报告 Mac 可无限缩小。标题栏原生桥已改为显式接收所属窗口的最小逻辑尺寸，在修改 `.fullSizeContentView` 后重设 `contentMinSize`，与 mini 共用同一内容约束。尺寸冒烟入口现支持 `-d macos`，会在真实标题栏配置后读取 AppKit 内容限制，并检查 mini 约束切换和关闭重开。当前环境为 Windows，尚未编译或运行该 Swift 修改；Mac 上的根因与修复效果均不能视为已验证。标题栏通道及窗口模式 11 项回归通过，受影响的 5 个 Dart 文件静态检查通过（仅 2 条既有 Material 导入弃用 info），扩展后的 Windows 原生尺寸冒烟也再次输出 `WINDOW CONSTRAINTS SMOKE COMPLETE`。提交前全量 228 项测试通过，补充超时退出后的尺寸冒烟入口静态检查无问题；原生尺寸 / 播放冒烟与 Release 构建结果见下文。

针对固定 SDK 创建窗口时未保存宿主尺寸约束的问题，Windows 适配层在创建后重新设置约束。`fvm flutter run -d windows --release -t integration_test/window_constraints_smoke.dart` 已输出 `WINDOW CONSTRAINTS SMOKE COMPLETE`：通过 Win32 `WM_GETMINMAXINFO` 查询拖动边缘时采用的真实原生限制，验证主窗口 900×600、播放器 720×405、切换到 mini 约束 420×260 后恢复，以及窗口间隔离与关闭重开。测试入口只操作隔离窗口，不读取媒体库；该检查不等于真实鼠标拖动或多显示器 / DPI 人工验收。

`fvm flutter analyze --no-fatal-infos` 通过（112 条既有 info，无错误 / 警告）；窗口控制与播放器窗口模式共 11 项测试通过。已有 `windowing_smoke.dart` 的 Windows Release 真实播放回归也输出 `WINDOWING SMOKE COMPLETE`，覆盖双视图、mini 尺寸、全屏、换片、关闭重开与最终进度落库。正式入口的 `fvm flutter build windows --release --no-pub` 构建通过。手工验收需分别缩小主窗口、播放器和 mini，并检查退出 mini 后最小尺寸恢复。

```bash
fvm flutter run -d windows --release -t integration_test/window_constraints_smoke.dart
```

### Windows 本地启动补充（2026-10-17）

后续用户报告：AXTree 错误持续输出，拖动调整窗口尺寸时应用退出。Windows 应用日志记录 `flutter_windows.dll + 0x3cf46`、`0xc0000005`（并伴随 `0xc000041d`）；使用该固定 SDK 的 PDB 解析到 `flutter::AccessibilityBridge::CreateRemoveReparentedNodesUpdate + 186`。这属于无障碍节点父子关系更新路径，与之前 `media_kit_video_plugin.dll` 注册崩溃不同；Flutter 上游有相同函数的 [崩溃报告 #175041](https://github.com/flutter/flutter/issues/175041) 和 [空父节点检查修复 #190903](https://github.com/flutter/flutter/pull/190903)。

此前 AppSlider 局部 Overlay 规避在隔离测试中消除了 AXTree 错误，但用户确认正式应用仍有问题；已按用户要求撤回该改动及隔离缩放入口。窗口缩放崩溃尚未解决。

随后按用户要求通过正式启动入口的 `MochiWidgetsBinding` 暂时关闭 Windows 无障碍语义树，不修改 SDK；单项 binding 测试验证 Windows 在持有语义请求时仍返回关闭、macOS 保持框架行为。Windows Debug 构建及启动成功，启动日志未再出现 AXTree 错误。此为临时禁用，窗口手工缩放仍待用户确认；不视为原生引擎根因已修复。

通过 FVM 安装并选择 `.fvmrc` 指定提交 `5ba8961b517919e97cd58e404b75dcdcf313017a`，执行 `fvm flutter pub get`、文案检查（277 条通过）、`fvm flutter gen-l10n` 和 `fvm flutter run -d windows`。发现并修复 `media_kit_video 2.0.1` 注册时解引用不存在的隐式视图导致的启动崩溃，补丁说明见 [Windows 构建指南](build-windows.md#media_kit_video-的无隐式视图兼容补丁)。修复后 Debug 构建通过，Flutter VM Service 建立，`Mochi Player` 主窗口进程报告正常响应。

提交前审查补齐消息窗口销毁后的窗口类注销，并移除旧窗口回调分支。`fvm flutter analyze --no-fatal-infos` 通过（112 条 info，无错误 / 警告），全量 228 项测试通过，Windows Release 构建通过。真实冒烟入口也使用 `MochiWidgetsBinding`；`fvm flutter run -d windows --release -t integration_test/windowing_smoke.dart` 输出 `WINDOWING SMOKE COMPLETE`，双视图、共享语言、纹理通知、置顶与 mini 尺寸、全屏、换片复用、关闭重开、最终进度落库 / SQLite 重开均通过，日志没有 AXTree 错误。该结果仍不替代手工拖动窗口边缘、真实媒体样片、DPI、输入和长期播放验收。

| 领域 | 主要位置 | 关注点 |
| --- | --- | --- |
| 数据层 | `test/core/infrastructure/database/` | 组合唯一键、外键 / CHECK、JSON、日期、事务、局部更新、级联 / 禁止删除、开发库并发重建、双后台连接、关闭重开 |
| 库查询 | `test/features/library/application/library_repository_test.dart` | 标题可用性、搜索 / 收藏 / 续播排序、有限结果、SQL 与领域规则一致性、共享订阅 |
| 存储 | `test/core/infrastructure/storage/` | 路径、凭据、浏览 / 扫描适配；SMB 假客户端不代表真实 NAS 连接通过 |
| 媒体源应用入口 | `test/features/library/application/storage_sources_service_test.dart`、`file_browser_provider_test.dart` | 临时连接释放、接受任务收尾、退出拒绝新操作、来源删除通知及迟到连接关闭 |
| 应用组装 | `test/app/bootstrap/` | 设置与趋势共享 TMDB 实例、应用查询与播放写入共享数据库，独立实例无隐藏全局配置 |
| 应用退出 | `test/app/application/` | 重复请求、保存 / 释放顺序、失败与超时、最终快照持久化 |
| 播放 | `test/features/playback/` | 引擎门面、轨道 / 字幕、seek、进度队列、创建 / 替换 / 关闭、mini / 全屏失败重试 |
| 本地化 | `test/l10n/` | 三种偏好、保存失败重试、ICU 与格式化、语言切换不重建会话 |
| 视图消息 | `test/core/ui/components/app_message_test.dart` | 两视图独立队列，销毁一个宿主不影响另一个 |

表变化需重新生成代码、增加版本与迁移测试，见 [数据模型](../architecture/data-model.md)。两个根目录测试 `filename_parser_test.dart` / `scrape_plan_test.dart` 尚未按镜像目录整理。

## 真实窗口 / 播放冒烟

```bash
fvm flutter run -d macos -t integration_test/windowing_smoke.dart
# Windows 验收机器：
fvm flutter run -d windows -t integration_test/windowing_smoke.dart
```

入口在临时目录生成十秒 160×90 RGB AVI，使用隔离 SQLite 与内存偏好，不读取用户媒体库或请求 TMDB。验证双视图、共享语言、按 viewId 置顶 / 尺寸、全屏、替换复用、单独关闭 / 重开、共享进度订阅和最终 SQLite 持久化。成功删除临时数据并打印 `WINDOWING SMOKE COMPLETE`；失败打印异常，不仅凭进程退出码判断通过。

入口不通过真实主窗口关闭按钮、Cmd+Q / Dock 操作触发退出，不替代手工验收。迁移过程观察过 frame-time clamping 日志，短片通过不能推断长期稳定或没有资源泄漏。

平台构建应串行，避免争用同一 Xcode 构建目录。无需复制 SDK、应用包或整份构建备份；测试仅生成临时视频与数据库，可清理可重建缓存，保留需要交付的产物和源码。

## 手工验收清单

各平台分别记录应用提交、SDK 提交、系统版本、媒体样片和结果；失败附步骤与日志。未记录用例视为未确认。

| 场景 | 操作 | 通过标准 |
| --- | --- | --- |
| 基本窗口 | 播放、聚焦、拖动 / 最小化 / 恢复、中英文输入、复制粘贴 | 主窗口持续响应，输入归属正确，无额外播放器 |
| 单独关闭 | 播放后关闭播放器，重开同一媒体 | 主窗口可操作，续播位置存在，无残留声音 / 窗口 |
| 主窗口退出 | 无播放器 / 播放中关闭主窗口；macOS 另测 Cmd+Q / 菜单 / Dock | 所有窗口 / 音频结束，进程退出，重启有最终进度 |
| mini / 全屏 | 切换 mini、置顶与全屏，分别重复两种关闭方式 | 原尺寸 / 约束 / 置顶恢复，界面状态符合实际窗口状态 |
| 竞争与失败 | 连续启动 / 换片 / 关闭，全屏转换中关闭，注入写入 / 释放超时 | 不重复播放、不残留窗口，失败有界且不伪称保存成功 |
| 对话框 | 添加 / 编辑目录，选取 / 取消字幕，中文路径、过滤、全屏下操作及父窗口关闭 | 绑定正确父窗口，失败有提示，不影响另一视图 |
| 真实媒体 | 本地 / WebDAV seek、切集、音轨、内嵌 / 外挂字幕、倍速、样式覆盖 | 音画、时间与轨道状态符合内容 |
| 解码与画质 | 各编码、软 / 硬解、HDR 样片，观察资源与日志 | 逐样片记录，不以 RGB AVI 或假引擎替代 |
| 语言与布局 | 三种偏好、重启、播放 / 换片中切换、英文长文案、已有弹层 | 双视图一致、不重开媒体，格式 / 复数正确，无溢出 |
| 边界与发布 | 多显示器 / DPI、跨 Spaces、遮挡 / 后台、长时间播放、键盘 / VoiceOver、安装启动 | 逐平台记录，构建与签名 / 公证分别确认 |

真实 SMB 浏览 / 超时与 HTTP 转发播放分别验证；已移除不可用的直链路径，回源已接入，真实 NAS 播放与 seek 仍待验收。Emby、系统 PiP 未实施，不加入本轮应通过的清单。

## CI 与待完善项

[Windows 工作流](../../.github/workflows/windows.yml) 读取固定 SDK 提交，执行依赖、本地化、静态检查、全量测试、Release 构建与产物上传。尚无 macOS CI，格式失败检查尚未加入工作流；本轮文档整理没有修改流水线。

后续补容量基线、可重复的媒体样片与平台人工结果；历史细节归档到验证历史，当前证据只在本指南汇总。
