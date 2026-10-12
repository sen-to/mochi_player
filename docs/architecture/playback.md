# 播放

本文描述「点击播放」到「进度写回媒体库」的链路与跨窗口协议。

```mermaid
sequenceDiagram
  participant UI as 媒体库主窗口
  participant MW as 播放器窗口（独立引擎）
  participant DB as 数据库
  participant MPV as media_kit / libmpv
  UI->>MW: 创建窗口 + PlayerWindowRequest(sourceId, path, 临时文件快照, 队列)
  MW->>DB: 初始化数据库并查找 MediaFile
  alt 媒体已入库
    DB-->>MW: MediaFile
  else 媒体未入库
    MW->>MW: 使用请求中的最小文件信息快照
  end
  MW->>MW: StorageSourcePlaybackResolver 解析播放目标
  MW->>MPV: PlaybackEngine.open(target, start)
  MW->>UI: player.ready
  loop 每 10 秒或位移超过 5 秒
    MW->>DB: 媒体已入库时写入播放进度
  end
  MW->>UI: player.closed（回传变更的媒体键）
  UI->>UI: 刷新媒体库状态
```

## 入口与跨窗口契约

- 入口：`PlaybackLauncher` 的 `playFile` / `playMovie` / `playTVShow` / `playEpisode`（[playback_launcher.dart](../../lib/features/playback/presentation/playback_launcher.dart)）。
- 播放队列：由 `MediaLibraryProvider.getPlaybackQueue` 生成——剧集按剧集分组、排序、去重；电影等为单元素队列。
- 请求对象：[player_window_request.dart](../../lib/features/playback/domain/player_window_request.dart)，**版本化**，携带 `sourceId + path`；临时文件浏览项额外携带文件名、大小等最小回退信息，**不含 URL 与凭据**。
- 窗口创建后由 [main.dart](../../lib/main.dart) 的入口分支识别并走 `runPlayerWindow`；播放器窗口自己初始化数据库与设置（[player_window_app.dart](../../lib/features/playback/presentation/player_window_app.dart)）。
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
| 独立窗口 | 默认形态；同一时间只保留一个播放器窗口，新请求替换现有窗口内容（`player.replaceRequest`） |
| mini 播放器 | 同一窗口缩至 480×300（最小 420×260），定位到屏幕右下角，默认置顶；macOS 下隐藏原生窗口按钮 |
| 全屏 | 区分应用内全屏状态与系统全屏，退出时同步 |

窗口操作通过 `WindowService` / `WindowHandle`；`DesktopWindowService` 封装当前插件后端，`PlayerWindowCoordinator` 串行处理启动、复用、就绪和退役，见 [0001](../decisions/0001-multi-window-strategy.md)。

产品规则为：关闭主窗口必须保存最终进度、关闭播放器并退出整个应用；单独关闭播放器不退出媒体库。已接入 `ApplicationExitCoordinator`：退出开始即拒绝新播放请求，先请求播放器准备关闭并确认保存 / 释放结果，再关闭子窗口、收尾后台任务与设置写入、关闭主数据库并退出整个进程。各阶段有超时；`player.closed` 变更通知不作为保存成功确认。

### 跨窗口方法

| 方向 | 方法 | 作用 |
| --- | --- | --- |
| 主 → 子 | `player.ready` | 等待播放器窗口就绪 |
| 主 → 子 | `player.replaceRequest` | 复用现有窗口播放新的请求 |
| 主 → 子 | `player.activate` | 聚焦已有窗口 |
| 主 → 子 | `player.prepareClose` | 等待最后进度、资源释放及子数据库关闭，返回 `prepared`、`saved`、`released` 与 `failedStages` |
| 主 → 子 | `player.close` | 回复后关闭已准备好的播放器窗口，主窗口继续等待其消失 |
| 子 → 主 | `player.closed` | 携带窗口 ID 和变更的媒体键列表；正常关闭时刷新主窗口，应用退出期间跳过刷新 |
| 原生 → 主 | `mochi_player/application_lifecycle.requestExit` | macOS 应用退出命令进入退出协调器 |
| 主/子 → 原生 | `mochi_player/window_controls` | macOS 原生按钮定位与显隐、关闭播放器窗口 |

## 字幕

- **语言优先级**：默认 `zh,chi,zho,chs,cht,eng`，既用于自动选轨，也直接写入 mpv 的 `slang`。
- **外挂字幕**：文件选择器限定 `srt / ass / ssa / vtt`；加载后按轨道标题回查（引擎不会回传新轨标识）。
- **样式覆盖**：开启覆盖时，把 `sub-ass` / `sub-visibility` / `secondary-sub-visibility` 统一置为关闭，改由 Flutter 依据播放器上报的字幕文本自行绘制，字号按播放器视口换算；关闭覆盖时交回 libass 处理。

外挂字幕在切换媒体时会清空，不跨集保留。

## 进度与续播

| 环节 | 规则 |
| --- | --- |
| 周期保存 | 每 10 秒一次（[player_playback_controller.dart:21](../../lib/features/playback/presentation/controllers/player_playback_controller.dart#L21)） |
| 位移阈值 | 与上次保存位置相差不足 5000ms 时跳过（`PlaybackSessionController.saveProgress`） |
| 强制保存 | 切换剧集、播放完成、关闭窗口前、组件销毁兜底 |
| 写入顺序 | `PlaybackProgressWriter` 串行化，避免旧快照覆盖新位置 |
| 落库 | `DatabasePlaybackMediaStore` → `DatabaseService.updateProgress`（同时推导观看状态，见 [data-model.md](data-model.md)） |
| 续播策略 | 位置回退 5 秒后开始；位置为 0 不续播；已完成（≥95%）不续播（[playback_resume_policy.dart](../../lib/features/playback/domain/playback_resume_policy.dart)） |

## 已知问题

| 问题 | 影响 |
| --- | --- |
| 窗口生命周期与平台交互 | Windows 输入冻结的完整根因与修复效果待验证；窗口退出协调已实施，Windows 原生交互与真实视频退出仍待运行时验收。两个 SQLite 连接当前保留，由 WAL 协调 |
| 控制器体量大 | 设置、字幕、进度、日志、缓冲逻辑集中在一个控制器中 |
| media_kit 有限维护 | 关键修复发布时间不可保证；播放后端已通过门面隔离，但原生渲染与打包仍需验证 |
| 播放中修改设置不生效 | 播放页初始化时读取一次设置 |
| 完成阈值重复 | 95% 在多处独立出现，见 [data-model.md](data-model.md) |

处置见 [0001](../decisions/0001-multi-window-strategy.md) 与 [0002](../decisions/0002-playback-engine.md)。
