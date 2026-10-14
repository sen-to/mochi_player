# 播放

核对日期：2026-10-14。本文描述「点击播放」到「进度写回媒体库」的链路与同引擎会话调用。功能状态见 [实施状态](../status.md)，验证证据见 [测试指南](../guides/testing.md)。

```mermaid
sequenceDiagram
  participant UI as 媒体库主窗口
  participant MW as 播放器视图（共享引擎）
  participant DB as 数据库
  participant MPV as media_kit / libmpv
  UI->>MW: 创建 / 复用视图 + 内存 PlayerWindowRequest
  MW->>DB: 共享连接查找 MediaFile
  alt 媒体已入库
    DB-->>MW: MediaFile
  else 媒体未入库
    MW->>MW: 使用请求中的文件对象
  end
  MW->>MW: StorageSourcePlaybackResolver 解析播放目标
  MW->>MPV: PlaybackEngine.open(target, start)
  loop 每 10 秒检查，位移至少 5 秒才保存
    MW->>DB: 媒体已入库时写入播放进度
  end
  DB-->>UI: 共享 drift 查询订阅刷新媒体库状态
```

## 入口与播放请求

- 入口：`PlaybackLauncher` 的 `playFile` / `playMovie` / `playTVShow` / `playEpisode`（[playback_launcher.dart](../../lib/features/playback/presentation/playback_launcher.dart)）。
- 播放队列：由 `MediaLibraryProvider.getPlaybackQueue` 生成——剧集按剧集分组、排序、去重；电影等为单元素队列。
- 请求对象：[player_window_request.dart](../../lib/features/playback/domain/player_window_request.dart)，在同一 isolate 内传递 `MediaFile`、队列和请求 ID，不再序列化 JSON 或维护版本协议。
- [PlayerWindowCoordinator](../../lib/features/playback/application/player_window_coordinator.dart) 通过 Provider 注入，串行创建 / 替换单个会话；播放入口直接调用协调器，不依赖全局静态转发层。[player_window_factory.dart](../../lib/app/bootstrap/player_window_factory.dart) 创建独立视图并协调窗口生命周期；[PlayerWindowController](../../lib/features/playback/application/player_window_controller.dart) 加载启动数据与维护会话展示状态；[player_window_app.dart](../../lib/features/playback/presentation/player_window_app.dart) 负责界面，共享设置、语言与主题。引擎工厂、数据库播放适配和目标解析器均由组装入口注入。
- [PlaybackMediaRepository](../../lib/features/playback/application/playback_media_repository.dart) 是应用契约；[DatabasePlaybackMediaRepository](../../lib/features/playback/infrastructure/database_playback_media_repository.dart) 是基础设施实现，使用注入的共享数据库。播放会话不自行创建数据库服务或媒体源解析器。
- 播放器优先按 `sourceId + path` 读取已入库记录；查不到时使用临时快照继续解析媒体源。因此文件浏览器播放不依赖扫描或 TMDB 刮削。未入库媒体的播放进度不会写入媒体库，扫描入库后才支持续播。

## 播放目标解析

播放器窗口读到 `MediaFile` 后，交给 [StorageSourcePlaybackResolver](../../lib/core/infrastructure/storage/storage_source_playback_resolver.dart) 按媒体源类型分派：

| 类型 | 解析结果 | 说明 |
| --- | --- | --- |
| 本地 | `file://` URL | 校验路径必须落在媒体源根目录内 |
| WebDAV | HTTP(S) URL + `Authorization: Basic` 头 | 由 FFmpeg 的 http 协议与 Range 支撑 |
| SMB | `smb://user:pass@host/share/...` | 当前实现会把直链交给 libmpv；用户已实测当前捆绑版本无法打开 / seek，HTTP 回源尚待实现，见 [0005](../decisions/0005-smb-playback-path.md) |

验证完成前，文档不应承诺 SMB 直链播放。临时方案是先在操作系统中挂载 SMB 共享，再将挂载目录作为本地媒体源添加。

媒体源被停用或不存在时解析失败，播放器窗口展示失败信息（失败提示只由子窗口负责，主窗口不重复报错）。

## 播放引擎

窗口入口选择 `MediaKitPlaybackEngine` 工厂，页面创建引擎并注入 `PlayerPlaybackController`。控制器和控制栏通过 [PlaybackEngine](../../lib/features/playback/application/playback_engine.dart) 使用项目状态与轨道类型，执行播放控制、状态订阅、选轨、字幕覆盖和缓存速度查询；视频视图也由后端提供。

[MediaKitPlaybackEngine](../../lib/features/playback/infrastructure/media_kit_playback_engine.dart) 内部创建 `Player`（启用 libass）与 `VideoController`，将 `PlaybackTarget` 的 URL、请求头与续播起点转换为后端媒体对象。以下 mpv 参数仅在此实现中下发：

| 参数 | 取值来源 |
| --- | --- |
| `cache` / `cache-pause` / `cache-pause-wait` | 固定值 |
| `cache-secs` / `demuxer-readahead-secs` | 设置：预读秒数 |
| `demuxer-max-bytes` / `demuxer-max-back-bytes` | 设置：缓存大小（后者为 1/4） |
| `hwdec` | 设置：硬件解码开关（`auto` / `no`） |
| `slang` | 设置：字幕语言优先级 |
| `vo-profile` | 固定 `high-quality` |

门面不暴露任意属性读写；缓存速度通过 `readCacheBytesPerSecond` 返回数值，字幕模式经类型明确的方法设置。参数实现与维护风险见 [0002](../decisions/0002-playback-engine.md)。

## 窗口模式

| 模式 | 行为 |
| --- | --- |
| 独立窗口 | 默认形态；同一时间只保留一个播放器窗口，新请求替换现有窗口内容（直接 `PlayerWindowSession.replace` 调用） |
| mini 播放器 | 同一窗口缩至 480×300（最小 420×260），以原窗口右下角为锚点，默认置顶；macOS 下隐藏原生窗口按钮 |
| 全屏 | 区分应用内全屏状态与系统全屏，退出时同步 |

窗口操作通过视图 Provider 中的 `WindowService`，不使用全局「当前窗口」。`DesktopWindowHost` 管理官方 registry，每个服务拥有独立 `viewId`；尺寸约束、激活和全屏使用官方控制器，拖动 / 位置 / 普通置顶和按视图绑定的文件对话框通过原生扩展。macOS 全屏的 Future 等待 AppKit 动画完成，超时会恢复实际 UI 状态并允许重试。小窗统一采用 mini 播放器，复用当前播放会话、字幕和控制界面；系统画中画暂不纳入实现与验收范围。

进入 mini 前记录原尺寸、最大化与置顶状态；退出时恢复这些状态及常规尺寸约束。mini 失败会尝试撤回部分修改，原尺寸记录在恢复成功后才清除；恢复失败保留重试信息，置顶失败读取实际状态。标题栏配置使用 `configureTitlebar`，没有手动移动 macOS 红绿灯坐标。

## 生命周期与退出

关闭主窗口进入 `ApplicationExitCoordinator`：拒绝新请求，等待已接受的会话操作、最终进度和资源释放，注销视图并等待一帧，再销毁窗口；随后收尾任务、设置与共享数据库，结束进程。播放器单独关闭不关闭共享数据库。

```mermaid
sequenceDiagram
  participant Main as 主窗口退出入口
  participant Exit as ApplicationExitCoordinator
  participant Player as 播放器会话
  participant DB as 共享数据库
  Main->>Exit: requestExit
  Exit->>Exit: 拒绝新播放、扫描与设置变更
  Exit->>Player: 等待已接受请求，暂停并保存最终进度
  Player->>DB: 串行提交进度
  DB-->>Player: 写入结果
  Player->>Player: 释放引擎，解绑页面与视图
  Player-->>Exit: 清理结果或超时
  Exit->>Exit: 等待应用任务与偏好写入
  Exit->>DB: 关闭共享连接
  Exit->>Exit: 结束整个进程
```

重复退出复用同一操作。播放器阶段最多 18 秒，应用清理阶段最多 8 秒；macOS 原生退出有 30 秒兜底。播放器内部对替换 / 保存 / 解绑帧阶段各等待最多 2 秒，资源释放与窗口恢复阶段最多 12 秒。失败继续后续清理，超时 / 强制结束不保证最后快照已保存，不能把“进程退出”当作“保存成功”。

替换播放请求先解析新目标；成功后保存、释放旧播放资源并移除旧页面一帧，再挂载新页面，避免两个页面同时拥有资源回调。目标解析失败保留原播放。语言变化只重建文案，不替换播放会话。

跨窗口 `player.*` / `app.*` RPC 已删除。macOS 退出原生通道仍负责将 Cmd+Q / Dock 退出导向同一退出协调器；窗口原生通道每次请求必须带 `viewId`，不根据焦点推测窗口身份。

## 字幕

- **语言优先级**：默认 `zh,chi,zho,chs,cht,eng`，既用于自动选轨，也直接写入 mpv 的 `slang`。
- **外挂字幕**：视图所属的系统文件对话框限定 `srt / ass / ssa / vtt`；加载后按轨道标题回查（引擎不会回传新轨标识）。
- **样式覆盖**：开启覆盖时，把 `sub-ass` / `sub-visibility` / `secondary-sub-visibility` 统一置为关闭，改由 Flutter 依据播放器上报的字幕文本自行绘制，字号按播放器视口换算；关闭覆盖时交回 libass 处理。

外挂字幕在切换媒体时会清空，不跨集保留。

## 进度与续播

| 环节 | 规则 |
| --- | --- |
| 周期保存 | 每 10 秒一次（[player_playback_controller.dart:21](../../lib/features/playback/presentation/controllers/player_playback_controller.dart#L21)） |
| 位移阈值 | 与上次保存位置相差不足 5000ms 时跳过（`PlaybackSessionController.saveProgress`） |
| 强制保存 | 切换剧集、播放完成、关闭窗口前、组件销毁兜底 |
| 写入顺序 | `PlaybackProgressWriter` 串行化，避免旧快照覆盖新位置 |
| 落库 | `DatabasePlaybackMediaRepository` → `DatabaseService.updateProgress`（同时推导观看状态，见 [data-model.md](data-model.md)） |
| 续播策略 | 位置回退 5 秒后开始；位置为 0 不续播；已完成（≥95%）不续播（[playback_resume_policy.dart](../../lib/features/playback/domain/playback_resume_policy.dart)） |

## 已知问题

| 问题 | 影响 |
| --- | --- |
| 窗口生命周期与平台交互 | Windows 输入冻结的完整根因与修复效果待验证；窗口退出协调已实施，Windows 原生交互与真实视频退出仍待运行时验收。两个视图共享一个后台 SQLite 连接 |
| 控制器体量大 | 设置、字幕、进度、日志、缓冲逻辑集中在一个控制器中 |
| media_kit 有限维护 | 关键修复发布时间不可保证；播放后端已通过门面隔离，但原生渲染与打包仍需验证 |
| 播放中修改设置不生效 | 播放页初始化时读取一次设置 |
| 完成阈值重复 | 95% 在多处独立出现，见 [data-model.md](data-model.md) |

处置见 [0001](../decisions/0001-multi-window-strategy.md) 与 [0002](../decisions/0002-playback-engine.md)。
