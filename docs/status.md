# 当前实施状态

整理日期：2026-10-31。下表是当前完成度与待办的统一入口；验证日期、测试结果与证据范围见 [测试指南](guides/testing.md#验证基线)。本轮重新执行 Dart 回归与架构检查，未重新执行原生平台验收。

## 功能状态

| 能力 | 当前实现 | 尚待完成 / 验收 |
| --- | --- | --- |
| [官方多视图](architecture/playback.md) | 单引擎，主视图 + 最多一个播放器；共享状态和数据库；主窗口关闭即退出 | 双平台原生输入、退出竞争、多显示器 / DPI 与长时间运行 |
| mini | 复用播放器窗口，缩小 / 置顶并恢复原状态 | 两平台真实媒体交互；系统 PiP 不在当前范围 |
| [播放引擎](architecture/playback.md#播放引擎) | PlaybackEngine 门面，唯一后端为 media_kit / libmpv | 两平台编码、音轨、字幕、硬解、HDR 与长时间样片 |
| [媒体库与持久化](architecture/data-model.md) | drift + SQLite schema 2，六表、约束 / 索引、共享后台连接与字段级写入；TMDB 请求失败与未匹配分类、失败保留原关联 | 大库容量、元数据回收、请求重试 / 退避、凭据安全存储；正式发布后的保留数据迁移 |
| [应用职责](architecture/overview.md#职责边界) | 页面通过应用入口操作；依赖显式组装；全仓库按功能及 ui / application / domain / data 职责组织；数据库 DO、业务模型、展示 VO 与边界 Mapper 分离，手写 Dart 文件具有中文职责说明，并负责播放前的库查询，向播放功能单向提交请求；来源与设置变更通过应用入口联动；字幕流程及进度条交互独立维护，播放会话统一拥有引擎与目标 | 真实平台、容量与端到端体验仍需验收；首页单向复用媒体库展示与详情入口 |
| [本地化](architecture/localization.md) | 中英 / 跟随系统，共享语言偏好与 ARB 生成 | 全页面布局、系统语言变化与原生界面交互 |
| 本地 / WebDAV | 浏览、扫描、URL 与认证头解析 | 真实媒体及不同服务端 / 网络条件 |
| [SMB 播放](architecture/playback.md#smb-http-回源) | dart_smb2 随机读 + 回环 HTTP Range；会话资源释放与快速 seek 请求替换 | 问题报告所用的 NAS / MP4 重测；真实认证、重连、高码率及 Windows 运行 |
| [媒体服务器计划](decisions/0006-media-server-integration.md) | Emby 优先方向已接受，尚未实现 | 账户、远端条目、播放协商与服务器进度上报 |
| 发布 | 尚无正式 Release 版本 | 签名 / 公证、安装验收与正式分发；CI 产物不等于正式发布 |

## 平台与工具链边界

- 固定 SDK 由 [`.fvmrc`](../.fvmrc) 管理，官方多视图仍使用实验能力；升级时需重新验证原生宿主与插件。
- Windows 因原生 AXTree 崩溃暂时关闭无障碍语义树，读屏不可用。SDK 最小窗口尺寸规避与插件补丁的移除条件见 [Windows 指南](guides/build-windows.md)。
- macOS 最小内容尺寸专项验收仍需单独记录，不能用播放冒烟替代真实拖动 / 约束检查；权限与标题栏机制见 [macOS 指南](guides/build-macos.md)。
- 仍使用旧 Material / Cupertino 导入；独立 UI 包迁移尚未进行。Windows CI 已加入 Dart 格式检查；SPM、macOS CI 和发布流程仍需完善。
- SMB 隔离 HTTP 冒烟不连接真实 NAS；Windows 历史 CI / 冒烟也不替代当前提交的人工验收。文件对话框的既有人工确认未逐项注明平台与边界。

架构与类名审查已落实；数据库入口统一为 AppDatabase，Repository 只隔离实际的功能数据能力，取消重复的 Store 包装与独立搜索计划工厂，查询界面及扫描会话名称明确；依赖、模型映射及中文文件说明由 CI 检查；详见 [统一边界决策](decisions/0007-unified-module-boundaries.md)。

后续优先补真实平台 / 媒体验收与容量基线。新增机制更新对应架构，验证结果更新测试指南；技术方向变化才修订 ADR。
