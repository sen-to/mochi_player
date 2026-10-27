# 0005 SMB 播放路径：不依赖 libmpv 的 smb://，改为本地 HTTP 回源

- **Status**: Accepted
- **Date**: 2026-10-23（初稿 2026-10-05）
- **Related**: [0002 播放引擎](0002-playback-engine.md)

## Context（背景与约束）

实施前：SMB 媒体源在扫描与浏览时使用 `dart_smb2`（`workers: 1`，单连接），播放解析器把文件拼成 `smb://user:pass@host/share/...` 直接交给 libmpv，不走本地缓存。直链实现已被回源方案替代，当前机制见 [播放架构](../architecture/playback.md#smb-http-回源)。

选型依据（捆绑版本的实测与外部实现资料分别表述）：

1. mpv 的 `smb://` 能力来自 FFmpeg 的 [`libavformat/libsmbclient.c`](https://android.googlesource.com/platform/external/ffmpeg/+/9c75148e6ebc88a0501e3d0242defb6dbdc3c23d%5E%21/libavformat/libsmbclient.c)，**必须在构建时链接 Samba 才存在**；发行版已陆续移除该选项（[FreeBSD 2020 年移除 mpv 的 SMB 支持](https://lists.freebsd.org/pipermail/freebsd-multimedia/2020-November/020926.html)、[Arch 相关工单](https://bugs.archlinux.org/task/69798)）。
2. 人工实测反馈显示，所用 `media_kit_libs_video` 捆绑的 libmpv 不能打开 / seek SMB 文件；具体是否因为缺少该协议仍需构建信息或日志确认。原解析器注释也把支持 SMB 写成假设，不能当作已具备的播放能力。
3. 该路径把凭据放进 URL 的 `userInfo`，可能泄漏到日志等诊断信息中；[playback_log_buffer.dart](../../lib/features/playback/application/playback_log_buffer.dart) 对 URL 与 Authorization 做脱敏，但脱敏不能消除凭据进入播放链路的风险。

对照：WebDAV 走 HTTP(S) 直链并附加 `Authorization` 头（[webdav_playback_resolver.dart](../../lib/core/data/storage/webdav_playback_resolver.dart)），由 FFmpeg 的 http 协议与 Range 支撑。

## 直链方案的历史实测依据

2026-10-11 的人工实测反馈记录：所用项目捆绑播放器不能打开 SMB 文件，也不能完成 seek，因此选择本地 HTTP 回源方案。回源的当前完成度与验证范围分别见 [实施状态](../status.md) 和 [测试指南](../guides/testing.md)。

该结论来自人工反馈，记录未附操作系统、服务端版本、样片与日志，不能据此推断所有 libmpv 构建均不支持 SMB。后续更换播放依赖或捆绑产物时，重新记录版本及打开 / seek 验证结果。

## Decision（决策）

**SMB 播放不依赖 libmpv 的 `smb://`，改为「Dart 侧读取 + 本地 HTTP 回源」。**

必须遵守的规则：

1. **SMB 播放采用 HTTP 回源方案**。更换捆绑产物后可重新评估，必须同时验证打开与 seek。
2. HTTP 回源服务**必须**只监听回环地址（`127.0.0.1`）、使用随机端口，并要求每次会话的随机令牌，不得对外暴露，也不得把凭据写入 URL。
3. 服务**必须**支持 `HEAD` 与**字节范围请求（Range）**：拖动进度条与跳转依赖随机读，缺失 Range 会导致 seek 失效或退化为顺序读取。
4. UI 不承诺依赖捆绑播放器的 SMB 直链能力；保留系统挂载（macOS mount_smbfs / Windows 映射网络驱动器）后作为本地媒体源播放的可选路径。
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
  - 相较直链增加一跳本机转发，其开销需结合高码率场景验证。
- **跟进**
  - 补充 SMB 直链实测反馈的环境与日志；当前结论为直链不可用；
  - 使用真实 NAS 验收连接、播放 / 续播、频繁 seek、换片与关闭；记录断线恢复及高码率表现；
  - 在 Windows 上复现协议测试与原生 HTTP 冒烟，确认 native SMB 依赖及 runner 行为；
  - 核对真实 NAS 与发布构建后再扩大用户文档中的可用性承诺，保留系统挂载作为可选方案。

## 相关文档

- [实施状态](../status.md)：完成度与待验收项。
- [SMB HTTP 回源](../architecture/playback.md#smb-http-回源)、[目标资源所有权](../architecture/playback.md#播放目标资源所有权)：协议、取消与关闭机制。
- [测试指南](../guides/testing.md)：协议回归、原生冒烟与 NAS 清单；逐轮结果见 [验证历史](../history/validation-2026-10.md)。
- [macOS 权限](../guides/build-macos.md#沙箱与权限)：回环监听所需的沙箱配置。

## Alternatives（备选与否决理由）

| 备选 | 评价 | 结论 |
| --- | --- | --- |
| 直接用 libmpv 的 `smb://` | 零额外代码；但可行性取决于预编译产物，且凭据进 URL | 当前捆绑版本实测不可用，不作为当前首选 |
| 用 VLC 播放 SMB | VLC 自带 SMB 支持（[`libdsm`](https://awesome.ecosyste.ms/projects/github.com%2Fvideolabs%2Flibdsm)），是 SMB 最省事的方案；但为一项协议引入第二套播放栈 | 否决，见 [0002](0002-playback-engine.md) |
| 先下载到本地缓存再播放 | 实现简单、seek 稳定；但启动延迟、占用磁盘、大文件体验差 | 否决 |
| 引导系统挂载后用本地目录 | 无需实现协议转发，但需用户在系统中管理挂载 | 保留为保底方案与回源方案上线前的过渡 |
| 换用其他 SMB 客户端库 | 可能改善浏览性能与并发 | 待观察：若 `dart_smb2` 停更或性能不达标再评估 |

## Revisit trigger（重估触发条件）

满足任一条即重新评估：

1. 协议探测证明捆绑的 libmpv 支持 `smb://` 且可正常 seek —— 此时直链作为首选，本决策的 HTTP 回源降级为备选；
2. `dart_smb2` 停止维护，或回源方案在实测码率下无法满足播放（给出具体阈值，例如 4K 高码率片源 seek 延迟超过 2 秒）；
3. 官方窗口/播放方案变更导致 mpv 直接绑定成为主线（见 [0002](0002-playback-engine.md)），届时重新评估 SMB 的整体接入方式。
