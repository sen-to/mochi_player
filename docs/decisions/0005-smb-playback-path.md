# 0005 SMB 播放路径：不依赖 libmpv 的 smb://，改为本地 HTTP 回源

- **Status**: Proposed
- **Date**: 2026-10-05
- **Related**: [0002 播放引擎](0002-playback-engine.md)

## Context（背景与约束）

现状：SMB 媒体源在扫描与浏览时使用 `dart_smb2`（[smb_storage_provider.dart](../../lib/core/infrastructure/storage/smb_storage_provider.dart)，`workers: 1`，单连接），
播放时由 [smb_playback_resolver.dart](../../lib/core/infrastructure/storage/smb_playback_resolver.dart) 把文件拼成 `smb://user:pass@host/share/...` 直接交给 libmpv，不走本地缓存。

风险点（**外部事实，需在落地前实测确认**）：

1. mpv 的 `smb://` 能力来自 FFmpeg 的 [`libavformat/libsmbclient.c`](https://android.googlesource.com/platform/external/ffmpeg/+/9c75148e6ebc88a0501e3d0242defb6dbdc3c23d%5E%21/libavformat/libsmbclient.c)，**必须在构建时链接 Samba 才存在**；发行版已陆续移除该选项（[FreeBSD 2020 年移除 mpv 的 SMB 支持](https://lists.freebsd.org/pipermail/freebsd-multimedia/2020-November/020926.html)、[Arch 相关工单](https://bugs.archlinux.org/task/69798)）。
2. `media_kit_libs_video` 捆绑的 libmpv 是否编译进该协议**未知**。解析器注释本身也把它写成假设：「once the bundled libmpv has SMB support」。
3. 该路径把凭据放进 URL 的 `userInfo`，会出现在日志与进程信息中（现有 [libmpv_log_buffer.dart](../../lib/features/playback/infrastructure/libmpv_log_buffer.dart) 已对 URL 与 Authorization 做脱敏，说明团队已意识到该风险，但脱敏是补救而非消除）。

对照：WebDAV 走 HTTP(S) 直链并附加 `Authorization` 头（[webdav_playback_resolver.dart](../../lib/core/infrastructure/storage/webdav_playback_resolver.dart)），由 FFmpeg 的 http 协议 + Range 支撑，是健康路径，本次不动。

## Decision（决策）

**SMB 播放不依赖 libmpv 的 `smb://`，改为「Dart 侧读取 + 本地 HTTP 回源」。**

必须遵守的规则：

1. **先做一次协议探测**（成本极低，决定后续工作量）：用当前捆绑的 libmpv 实测 `smb://` 是否可打开。探测通过则本决策降级为备选并保留直链；探测失败则按下述方案实施。
2. HTTP 回源服务**必须**只监听回环地址（`127.0.0.1`）、使用随机端口，并要求每次会话的随机令牌，不得对外暴露，也不得把凭据写入 URL。
3. 服务**必须**支持 `HEAD` 与**字节范围请求（Range）**：拖动进度条与跳转依赖随机读，缺失 Range 会导致 seek 失效或退化为顺序读取。
4. 在 HTTP 回源可用之前，**UI 不得承诺 SMB 直链播放**；此期间提供保底路径：引导用户在系统层挂载（macOS `mount_smbfs`、Windows 映射网络驱动器）后用「本地目录」媒体源播放，并在文档中写明。
5. SMB 凭据只保留一份来源：浏览与播放共用同一份读取路径，避免两套实现各自的凭据处理。

## Consequences（后果）

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
  - 协议探测脚本/手工验证，并记录结论；
  - 若确认需要 HTTP 回源：实现回源服务（Range + 令牌 + 单会话绑定），补单元测试（Range 边界、并发读、断连回收）；
  - **补齐 macOS Release 的 `network.server` 权限**：当前该权限只在 [DebugProfile.entitlements](../../macos/Runner/DebugProfile.entitlements) 中声明，[Release.entitlements](../../macos/Runner/Release.entitlements) 没有；回源服务需要监听回环端口，缺失该权限会导致发布构建下监听被沙箱拒绝（详见 [macOS 构建指南](../guides/build-macos.md#沙箱与权限)）；
  - 更新用户文档中 SMB 播放的说明与保底方案。

## Alternatives（备选与否决理由）

| 备选 | 评价 | 结论 |
| --- | --- | --- |
| 直接用 libmpv 的 `smb://` | 零额外代码；但可行性取决于预编译产物，且凭据进 URL | 先探测；通过则保留为首选，否则否决 |
| 用 VLC 播放 SMB | VLC 自带 SMB 支持（[`libdsm`](https://awesome.ecosyste.ms/projects/github.com%2Fvideolabs%2Flibdsm)），是 SMB 最省事的方案；但为一项协议引入第二套播放栈 | 否决，见 [0002](0002-playback-engine.md) |
| 先下载到本地缓存再播放 | 实现简单、seek 稳定；但启动延迟、占用磁盘、大文件体验差 | 否决 |
| 引导系统挂载后用本地目录 | 零开发成本、最稳定 | 保留为保底方案与回源方案上线前的过渡 |
| 换用其他 SMB 客户端库 | 可能改善浏览性能与并发 | 待观察：若 `dart_smb2` 停更或性能不达标再评估 |

## Revisit trigger（重估触发条件）

满足任一条即重新评估：

1. 协议探测证明捆绑的 libmpv 支持 `smb://` 且可正常 seek —— 此时直链作为首选，本决策的 HTTP 回源降级为备选；
2. `dart_smb2` 停止维护，或回源方案在实测码率下无法满足播放（给出具体阈值，例如 4K 高码率片源 seek 延迟超过 2 秒）；
3. 官方窗口/播放方案变更导致 mpv 直接绑定成为主线（见 [0002](0002-playback-engine.md)），届时重新评估 SMB 的整体接入方式。
