# 0005 SMB 播放路径：不依赖 libmpv 的 smb://，改为本地 HTTP 回源

- **Status**: Accepted
- **Date**: 2026-10-23（初稿 2026-10-05）
- **Related**: [0002 播放引擎](0002-playback-engine.md)

## Context（背景与约束）

实施前：SMB 媒体源在扫描与浏览时使用 `dart_smb2`（`workers: 1`，单连接），播放解析器把文件拼成 `smb://user:pass@host/share/...` 直接交给 libmpv，不走本地缓存。该直链实现现已移除；当前实现见下方实施状态。

风险点（**外部事实，需在落地前实测确认**）：

1. mpv 的 `smb://` 能力来自 FFmpeg 的 [`libavformat/libsmbclient.c`](https://android.googlesource.com/platform/external/ffmpeg/+/9c75148e6ebc88a0501e3d0242defb6dbdc3c23d%5E%21/libavformat/libsmbclient.c)，**必须在构建时链接 Samba 才存在**；发行版已陆续移除该选项（[FreeBSD 2020 年移除 mpv 的 SMB 支持](https://lists.freebsd.org/pipermail/freebsd-multimedia/2020-November/020926.html)、[Arch 相关工单](https://bugs.archlinux.org/task/69798)）。
2. `media_kit_libs_video` 捆绑的 libmpv 已由用户实测不能打开 / seek SMB 文件；具体是否因为缺少该协议仍需构建信息或日志确认。原解析器注释也把支持 SMB 写成假设，不能当作已具备的播放能力。
3. 该路径把凭据放进 URL 的 `userInfo`，会出现在日志与进程信息中（现有 [playback_log_buffer.dart](../../lib/features/playback/application/playback_log_buffer.dart) 已对 URL 与 Authorization 做脱敏，说明团队已意识到该风险，但脱敏是补救而非消除）。

对照：WebDAV 走 HTTP(S) 直链并附加 `Authorization` 头（[webdav_playback_resolver.dart](../../lib/core/infrastructure/storage/webdav_playback_resolver.dart)），由 FFmpeg 的 http 协议 + Range 支撑，是健康路径，本次不动。

## 当前捆绑版本实测结论

2026-10-11 用户确认：已实测当时项目捆绑播放器，不能打开 SMB 文件，也不能完成 seek。因此 `smb://` 直链不可作为可用播放能力，接受本地 HTTP 回源方向，当时先实施 ADR 0001。2026-10-23 已接入回源，验证范围见下文。

这是用户提供的当前捆绑版本实测结果，不是本次代理重新执行的测试。尚未提供操作系统、服务端版本、样片与日志记录，不能据此推断所有 libmpv 构建均不支持 SMB。后续更换播放依赖或捆绑产物时，重新记录版本及打开 / seek 验证结果。

## Decision（决策）

**SMB 播放不依赖 libmpv 的 `smb://`，改为「Dart 侧读取 + 本地 HTTP 回源」。**

必须遵守的规则：

1. **当前捆绑版本已由用户验证直链不可用**，后续按 HTTP 回源方案实施；不重复将协议探测列为前置待办。更换捆绑产物后可重新评估，必须同时验证打开与 seek。
2. HTTP 回源服务**必须**只监听回环地址（`127.0.0.1`）、使用随机端口，并要求每次会话的随机令牌，不得对外暴露，也不得把凭据写入 URL。
3. 服务**必须**支持 `HEAD` 与**字节范围请求（Range）**：拖动进度条与跳转依赖随机读，缺失 Range 会导致 seek 失效或退化为顺序读取。
4. 在 HTTP 回源可用之前，**UI 不得承诺 SMB 直链播放**；此期间提供保底路径：引导用户在系统层挂载（macOS `mount_smbfs`、Windows 映射网络驱动器）后用「本地目录」媒体源播放，并在文档中写明。
5. SMB 凭据只保留一份来源：浏览与播放共用同一份读取路径，避免两套实现各自的凭据处理。

## Consequences（后果）

### 实施状态（2026-10-23）

- [SmbPlaybackResolver](../../lib/core/infrastructure/storage/smb_playback_resolver.dart) 调用 [Smb2MediaReader](../../lib/core/infrastructure/storage/smb_media_reader.dart) 打开文件并取得真实长度；使用持久句柄、按偏移分块读取，不整部下载。单句柄操作串行执行，连接与读取由 dart_smb2 的后台 worker 处理。
- [SmbHttpPlaybackProxy](../../lib/core/infrastructure/storage/smb_http_playback_proxy.dart) 只绑定 `127.0.0.1:0`，每个文件生成 256 位随机令牌；令牌放在查询参数，由既有日志脱敏。只接受正确 Host、路径与令牌的 GET / HEAD；不暴露 SMB 凭据、目录或任意路径访问。
- 支持单段、开放结束与后缀字节范围；越界 416，普通请求 200，范围请求 206。HEAD 忽略 Range；不支持的多段 / 无效 Range 或无法验证的 If-Range 回退完整内容。每次最多读取 256 KiB，HTTP 写入等待背压；最多同时服务 4 个传输，超出时取消最旧传输并服务新请求，不返回 503 阻断最新 seek。被取消的排队读取不再进入 SMB；已执行的单块读取完成后丢弃结果。播放 SMB 连接协议超时 8 秒，HTTP 层读取 / 写入等待上限 12 秒。
- `PlaybackTarget.resource` 由播放会话持有；换片尝试结束后（包括失败）释放旧目标，销毁引擎后释放当前目标，关闭期间迟到的目标也会释放。窗口工厂补齐创建失败、替换失败 / 取消及未挂载页面的目标释放。关闭操作幂等，先停止 HTTP，再关闭 SMB 句柄与 worker。
- 浏览和播放共用来源仓库的凭据读取入口及连接参数组装。播放使用独立连接，不复用浏览的活动句柄；初始连接创建在应用内串行排队。
- macOS Release 已补齐 `network.server`。协议与会话自动化回归、macOS Release 的真实 media_kit HTTP 播放 / 前后 seek 冒烟通过；冒烟文件读取替身不访问真实 NAS。Windows、真实 NAS 认证 / 重连、高码率与长时间表现仍待验收，不能标记为全平台已完成。

### 影响与后续

- **正面**
  - 播放链路不再依赖第三方预编译产物是否包含某个协议，行为可测、可日志、可回归；
  - seek 行为由回源服务的 Range 实现决定，问题可定位；
  - 凭据不再出现在 URL 中；
  - 与 [0002](0002-playback-engine.md) 的门面化目标一致：mpv 侧只需处理 `http(s)`，能力要求收窄。
- **负面**
  - 新增一个本地服务与其生命周期管理（随播放启动、随窗口关闭回收、异常端口占用处理）；
  - 性能取决于 Dart 侧 SMB 读取实现（当前 `workers: 1`），高码率片源的并发读需要压测；
  - 相较直链多一跳本地转发（回环，开销可忽略但需要验证大码率场景）。
- **跟进**
  - 补充用户实测的环境与日志记录；当前结论为直链不可用；
  - 使用真实 NAS 验收连接、播放 / 续播、频繁 seek、换片与关闭；记录断线恢复及高码率表现；
  - 在 Windows 上复现协议测试与原生 HTTP 冒烟，确认 native SMB 依赖及 runner 行为；
  - 核对真实 NAS 与发布构建后再扩大用户文档中的可用性承诺，保留系统挂载作为可选方案。

## Alternatives（备选与否决理由）

| 备选 | 评价 | 结论 |
| --- | --- | --- |
| 直接用 libmpv 的 `smb://` | 零额外代码；但可行性取决于预编译产物，且凭据进 URL | 当前捆绑版本实测不可用，不作为当前首选 |
| 用 VLC 播放 SMB | VLC 自带 SMB 支持（[`libdsm`](https://awesome.ecosyste.ms/projects/github.com%2Fvideolabs%2Flibdsm)），是 SMB 最省事的方案；但为一项协议引入第二套播放栈 | 否决，见 [0002](0002-playback-engine.md) |
| 先下载到本地缓存再播放 | 实现简单、seek 稳定；但启动延迟、占用磁盘、大文件体验差 | 否决 |
| 引导系统挂载后用本地目录 | 零开发成本、最稳定 | 保留为保底方案与回源方案上线前的过渡 |
| 换用其他 SMB 客户端库 | 可能改善浏览性能与并发 | 待观察：若 `dart_smb2` 停更或性能不达标再评估 |

## Revisit trigger（重估触发条件）

满足任一条即重新评估：

1. 协议探测证明捆绑的 libmpv 支持 `smb://` 且可正常 seek —— 此时直链作为首选，本决策的 HTTP 回源降级为备选；
2. `dart_smb2` 停止维护，或回源方案在实测码率下无法满足播放（给出具体阈值，例如 4K 高码率片源 seek 延迟超过 2 秒）；
3. 官方窗口/播放方案变更导致 mpv 直接绑定成为主线（见 [0002](0002-playback-engine.md)），届时重新评估 SMB 的整体接入方式。
