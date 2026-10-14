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
| macOS 全量 Dart 回归 | 209 项通过 | 数据库、查询、设置、播放 / 窗口协调、UI；数量以当次日志为准 |
| 文案检查与生成 | 277 条检查通过，gen-l10n 成功 | 不等于所有页面布局与原生菜单语言已验收 |
| macOS Debug / Release | 迁移期间构建通过，依赖升级后 Debug 构建通过 | 不等于签名 / 公证或所有旧产物反映最新源码 |
| macOS 原生播放冒烟 | 修正全屏动画等待后，完成播放、退出、SQLite 重开 | RGB AVI 与隔离数据；主窗口关闭由程序内回调触发 |
| Windows 自动测试 | [第二次 CI](https://github.com/sen-to/mochi_player/actions/runs/38509922678/job/115675829212) 静态检查与 209 项测试通过 | 同次原生构建失败，后续单独修复 |
| Windows CI 最终结果 | 修复宏冲突后，用户确认 CI 成功 | 确认构建通过；未记录成功运行链接，不代替运行时验收 |
| 文件对话框 | 用户确认手工验收完成 | 未逐项列出平台 / 边界，不能推广为 Windows 全套对话框验收 |
| 标题栏方法重命名 | 3 项通道测试、Swift 语法检查通过 | 统一为 configureTitlebar，不证明原生页面视觉效果 |

自动化不替代真实媒体、原生窗口、进程退出和发布验证。Windows 运行时、长时间播放、多显示器 / DPI、硬解、HDR、可访问性和发布仍待验收；系统 PiP 不在范围内。

## 回归覆盖索引

| 领域 | 主要位置 | 关注点 |
| --- | --- | --- |
| 数据层 | `test/core/infrastructure/database/` | 唯一键、JSON、日期、事务、局部更新、删除、双后台连接、关闭重开 |
| 库查询 | `test/features/library/application/library_repository_test.dart` | 标题可用性、搜索 / 收藏 / 续播排序、有限结果、SQL 与领域规则一致性、共享订阅 |
| 存储 | `test/core/infrastructure/storage/` | 路径、凭据、浏览 / 扫描适配；SMB 假客户端不代表真实 NAS 连接通过 |
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

真实 SMB 浏览 / 超时与捆绑播放器协议能力分别验证；直链播放实测失败，HTTP 回源尚未实现。Emby、系统 PiP 未实施，不加入本轮应通过的清单。

## CI 与待完善项

[Windows 工作流](../../.github/workflows/windows.yml) 读取固定 SDK 提交，执行依赖、本地化、静态检查、全量测试、Release 构建与产物上传。尚无 macOS CI，格式失败检查尚未加入工作流；本轮文档整理没有修改流水线。

后续补容量基线、可重复的媒体样片与平台人工结果；历史细节归档到验证历史，当前证据只在本指南汇总。
