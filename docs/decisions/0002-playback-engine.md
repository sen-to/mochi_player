# 0002 播放引擎：继续使用 libmpv（经 media_kit），收敛 mpv 交互门面

- **Status**: Accepted
- **Date**: 2026-10-12（初稿 2026-10-05）
- **Related**: [0001 多窗口策略](0001-multi-window-strategy.md)、[0005 SMB 播放路径](0005-smb-playback-path.md)

## Context（背景与约束）

播放能力要求（作为替代方案评估与验收基线）：

| 能力 | 要求 |
| --- | --- |
| 容器 / 编码 | MKV、MP4；H.264、HEVC、AV1 |
| 字幕 | 内嵌与外挂 ASS/SSA/SRT/VTT；可覆盖字体与颜色；语言优先级选择 |
| 音频 | 多音轨切换、声道下混（2.0 / 5.1 / 7.1 标识与播放） |
| 画质 | HDR10 / 杜比视界文件的正常播放与映射；硬件解码开关 |
| 播放控制 | 0.5×–2× 变速、进度跳转、缓存与预读可配置 |
| 网络 | HTTP(S) 直链（含 WebDAV 带认证头）、局域网共享（当前捆绑播放器的 SMB 直链已实测不可用，[0005](0005-smb-playback-path.md) 的 HTTP 回源待实施与验收） |
| 平台 | macOS 12+ 与 Windows 桌面，单进程内嵌渲染 |

这张表是验收标准，不代表各项已完成实测。仓库目前没有覆盖两平台、HDR / 杜比视界、多音轨与字幕呈现的完整样片验收记录；这些能力在记录验证结果前应视为待验收。

现状：`media_kit 1.2.6` + `media_kit_video 2.0.1` + `media_kit_libs_video 1.0.7`，底层 libmpv。

本轮实施前，控制器通过 `NativePlayer.setProperty` 下发缓存、预读、硬件解码与字幕参数，控制栏通过 `getProperty` 读取缓存速度，页面直接持有 `VideoController`。本轮已收敛到下述门面，业务与 UI 使用项目自己的状态、轨道和设置类型。

### media_kit 维护风险（2026-10-12 核查）

- 作者于 **2025-11-25** 发布 [Limited Maintenance 公告](https://github.com/media-kit/media-kit/issues/1337)：没有全职团队，主要处理关键问题及相关 PR，不能将及时修复或新功能支持作为项目依赖条件。
- [pub.dev 发布列表](https://pub.dev/packages/media_kit/versions) 的最新正式版本仍为 `1.2.6`；[查到的主干提交记录](https://github.com/media-kit/media-kit/commits/main/) 包含 2026-08-30 的内存泄漏修复，以及此前的渲染、热重启和原生库更新。有限维护不等于停止维护，主干修复也不等于已包含在当前锁定版本中。
- 社区仍有贡献，包括尚未合并的 [Windows 窗口实例与全屏状态 PR #1448](https://github.com/media-kit/media-kit/pull/1448)。它与多窗口场景相关，不能据此认定本项目 Windows 冻结已定位或修复。

结论：当前保留 media_kit 后端，同时具备在后端层维护局部补丁的准备；维护风险已确认，完整播放能力仍按上表验收，不能写成「media_kit 已满足全部需求」。

## Decision（决策）

**继续以 libmpv 作为唯一播放内核（当前经 media_kit 接入），不更换引擎。**

必须遵守的规则：

1. **收敛引擎交互**：所有 mpv 专有参数、轨道切换、字幕样式、进度与状态订阅，必须经由单一播放引擎门面（接口名 `PlaybackEngine`，mpv 参数集中在它的实现内）。UI 与业务层不得直接触碰 `NativePlayer`、`player.platform` 或后端轨道 / 状态对象；视频视图由后端通过门面提供。不得把通用 `setProperty` / `getProperty` 作为门面公开 API。
2. **新依赖 mpv 专有能力时，必须同时登记进上表**：即先补充验收标准，再使用该能力，避免能力悄悄变成事实标准。
3. **不得为单一功能引入第二套播放栈**（例如为 SMB 引入 libvlc，见 [0005](0005-smb-playback-path.md)）。

## Consequences（后果）

- **正面**
  - 继续使用当前播放实现，避免为覆盖这些需求而维护第二套播放栈；具体媒体格式、HDR 与音轨表现按上方验收基线实测确认；
  - 项目采用 GPL-3.0-only，与 libmpv 的 LGPL/GPL 许可相容；
  - 门面化之后，未来若改为直接绑定 libmpv（`mpv_render_context`），改动面被限制在一层内——与 [0001](0001-multi-window-strategy.md) 的窗口服务边界配合。门面不会自动解决图形上下文、视频渲染与硬解兼容。
- **负面**
  - 播放内核事实上被锁定为 mpv：切换引擎意味着产品能力回退，而不是简单替换依赖；
  - 安装包体积包含完整 libmpv 与编解码依赖；
  - `media_kit` 已明确有限维护；版本升级、局部补丁与原生构建验证仍需项目自行承担。
- **跟进**
  - 门面已实施；后续新增能力必须通过类型明确的接口和后端实现接入，避免重新泄漏 mpv 参数；
  - 把上面的需求表补进测试或手工验收清单，作为替代方案评估基准。

## 实施状态（2026-10-12）

已实施：

- [PlaybackEngine](../../lib/features/playback/application/playback_engine.dart) 提供打开媒体、暂停 / 切换播放、seek、音量 / 倍速、音轨 / 字幕选择、类型明确的缓存 / 硬解 / 语言设置、字幕覆盖模式、缓存速度与状态流，并提供 Flutter 视频视图与资源释放入口。
- [PlaybackTrack](../../lib/features/playback/domain/playback_track.dart) 定义项目轨道类型，区分嵌入轨、自动、关闭及外挂来源，保留标题、语言、默认轨、音频编码与声道信息；门面不返回 media_kit 对象。
- [MediaKitPlaybackEngine](../../lib/features/playback/infrastructure/media_kit_playback_engine.dart) 是唯一当前后端，内部拥有 `Player` / `VideoController`，完成轨道与状态转换、HTTP 请求头、日志脱敏和所有 mpv 属性读写。切换 / 退出时使未完成的参数批次失效，释放接口幂等。
- `PlayerPlaybackController` 使用注入的门面处理播放命令、状态流、续播和字幕策略，队列 / URL 解析与串行进度由 `PlaybackSessionController` 协调；页面、控制栏、键盘操作均经门面访问播放与渲染。应用组装入口选择后端工厂，窗口工厂与页面使用注入的工厂，不导入或选择具体后端类型。
- 播放窗口由 `app/bootstrap/player_window_factory.dart` 组装，展示状态在 `PlayerWindowState`，界面在 `PlayerWindowApp`。`PlaybackMediaStore` 仅定义应用契约，数据库实现位于 `infrastructure/database_playback_media_store.dart`，使用注入的共享连接。
- 回归测试使用假引擎验证媒体目标与设置传递、轨道状态 / 外挂字幕选择、控制栏播放 / seek，以及暂停后最终保存、保存后释放和重复释放行为。

2026-10-14 小窗决策：继续使用 mini 播放器，复用同一播放会话、视频表面、字幕与控制逻辑。暂不为系统 PiP 扩展 `PlaybackEngine` 或增加 AVKit 视频帧出口；具体取舍见 [ADR 0001](0001-multi-window-strategy.md)。

待验收 / 跟进：

- 上表中的两平台媒体样片、硬解、HDR / 杜比视界、字幕呈现及真实视频 mini / 全屏退出验收；门面迁移通过检查不代表这些能力已验收。
- 本轮未直接绑定 libmpv，未改动播放依赖版本或捆绑产物，也未实现 SMB HTTP 回源。
- 直接 libmpv 迁移原型须同时验证 macOS / Windows 的视频嵌入、硬解、字幕、seek、事件线程、资源释放和打包；在验收前不替换当前后端，不长期保留两套业务流程。

## Alternatives（备选与否决理由）

| 备选 | 能力对比 | 否决理由 |
| --- | --- | --- |
| **VLC / libvlc** | 格式与字幕能力接近；SMB 是它的强项（自带 [`libdsm`](https://awesome.ecosyste.ms/projects/github.com%2Fvideolabs%2Flibdsm)） | Flutter 桌面上缺少成熟的嵌入式渲染封装（`flutter_vlc_player` 以移动端为主），为一项网络协议能力付出整套播放栈迁移成本不划算 |
| **平台原生播放器**（AVPlayer / Media Foundation） | 硬件路径与系统集成好、体积小 | MKV 容器、ASS 字幕、多音轨、HDR 元数据支持不足，且需要维护两套完全不同的实现，与「私人影片库」的核心场景冲突 |
| **FFmpeg 自绘 / GStreamer** | 可控性最高，能力也足够 | 等于自行实现渲染、音频输出、音画同步与字幕排版，成本远高于收益 |
| **直接绑定 libmpv（不经 media_kit）** | 控制力更强，可按窗口方案渲染到原生子窗口 | 当前保留为备选：有限维护风险已确认，但尚未验证直接接入的收益足以覆盖事件线程、视频输出、两平台构建与生命周期维护成本；出现阻塞缺陷或渲染需求时制作原型 |

## Revisit trigger（重估触发条件）

满足任一条即重新评估：

1. libmpv 无法满足新增的硬需求（例如某类杜比视界文件必须直通、或需要 mpv 未覆盖的格式）；
2. `media_kit` 的有限维护实际造成阻塞：关键问题长期没有可用修复、目标 Flutter 版本无法兼容，或捆绑原生库无法满足需求。先评估版本升级、局部补丁或替换捆绑产物；不足以解决时优先制作直接 libmpv 原型；
3. [0001](0001-multi-window-strategy.md) 决定走「原生子窗口 + 播放器渲染到原生窗口」，届时需要重新评估是否保留 media_kit 这一层。
