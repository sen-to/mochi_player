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
| 网络 | HTTP(S) 直链（含 WebDAV 带认证头）、局域网共享（不依赖不可用的 SMB 直链，[0005](0005-smb-playback-path.md) 的本地 HTTP 回源方案） |
| 平台 | macOS 12+ 与 Windows 桌面，单进程内嵌渲染 |

这张表是验收标准，不代表各项已完成实测。仓库目前没有覆盖两平台、HDR / 杜比视界、多音轨与字幕呈现的完整样片验收记录；这些能力在记录验证结果前应视为待验收。

决策时的依赖：`media_kit 1.2.6` + `media_kit_video 2.0.1` + `media_kit_libs_video 1.0.7`，底层 libmpv；实际锁定版本以 pubspec.lock 为准。

收敛前，控制器通过 `NativePlayer.setProperty` 下发缓存、预读、硬件解码与字幕参数，控制栏通过 `getProperty` 读取缓存速度，页面直接持有 `VideoController`。这些后端类型和参数散落在业务与 UI 中，是引入门面的原因。

### media_kit 维护风险（2026-10-12 核查）

- 作者于 **2025-11-25** 发布 [Limited Maintenance 公告](https://github.com/media-kit/media-kit/issues/1337)：没有全职团队，主要处理关键问题及相关 PR，不能将及时修复或新功能支持作为项目依赖条件。
- 该次核查时，[pub.dev 发布列表](https://pub.dev/packages/media_kit/versions) 的最新正式版本为 `1.2.6`；[主干提交记录](https://github.com/media-kit/media-kit/commits/main/) 包含 2026-08-30 的内存泄漏修复，以及此前的渲染、热重启和原生库更新。有限维护不等于停止维护，主干修复也不等于已包含在项目锁定版本中。
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
  - 新增能力必须通过类型明确的接口和后端实现接入，避免重新泄漏 mpv 参数；
  - 把上面的需求表补进测试或手工验收清单，作为替代方案评估基准。

## 相关文档

- [实施状态](../status.md)：完成度与待办。
- [引擎门面与后端实现](../architecture/playback.md)：当前代码机制。
- [测试与验收](../guides/testing.md)：验证证据与操作清单；逐轮记录见 [验证历史](../history/validation-2026-10.md)。

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
