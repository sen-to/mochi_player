# Mochi Player 文档

本目录存放开发文档与决策记录。面向用户的说明（功能、下载、快捷键、已知限制）保留在仓库根 [README](../README.md)。

## 索引

### 决策记录（ADR）

技术选型与架构决策的唯一落点。新决策请复制 [decisions/0000-template.md](decisions/0000-template.md)。

| 编号 | 决策 | 状态 | 日期 |
| --- | --- | --- | --- |
| [0001](decisions/0001-multi-window-strategy.md) | 多窗口策略：保留多窗口，把「引擎」从架构中摘除，目标迁移到官方单引擎多视图 | Accepted | 2026-10-05 |
| [0002](decisions/0002-playback-engine.md) | 播放引擎：继续使用 libmpv（经 media_kit），收敛 mpv 交互门面 | Accepted | 2026-10-05 |
| [0003](decisions/0003-persistence-migration.md) | 持久化：Isar 3 迁往 drift + SQLite | Proposed | 2026-10-05 |
| [0004](decisions/0004-i18n-l10n.md) | 国际化与本地化：官方 gen-l10n + ARB（`app_en.arb` 模板 / `app_zh.arb` 译文） | Accepted | 2026-10-05 |
| [0005](decisions/0005-smb-playback-path.md) | SMB 播放路径：不依赖 libmpv 的 `smb://`，改为本地 HTTP 回源 | Proposed | 2026-10-05 |

状态含义：`Proposed` 已提出待确认；`Accepted` 已决定并按此执行；`Superseded by NNNN` 已被后续决策替代。

### 架构说明

描述「现状是什么」，与 ADR 的「决定做什么」区分开：

| 文档 | 内容 |
| --- | --- |
| [architecture/overview.md](architecture/overview.md) | 分层与依赖方向、启动流程、核心抽象、已知架构问题 |
| [architecture/data-model.md](architecture/data-model.md) | 存储分工、Isar 表与索引、领域模型映射、进度推导、设置键 |
| [architecture/media-pipeline.md](architecture/media-pipeline.md) | 扫描 → 文件名解析 → TMDB 刮削 → 索引与展示 |
| [architecture/playback.md](architecture/playback.md) | 播放链路、跨窗口协议、窗口模式、字幕、进度写入 |

### 指南

与根 [README](../README.md) 的「从源码运行」互补，收录平台特有细节与排障：

| 文档 | 内容 |
| --- | --- |
| [guides/build-macos.md](guides/build-macos.md) | SPM 关闭、沙箱权限（含 Release 缺少 `network.server` 的坑）、窗口外观 |
| [guides/build-windows.md](guides/build-windows.md) | UI 线程策略、CI 流程、多窗口已知问题 |
| [guides/testing.md](guides/testing.md) | 测试分层与运行方式、代码约定、待补项 |

### 图片

| 目录 | 用途 | 约定 |
| --- | --- | --- |
| [images/screenshots](images/screenshots/) | 产品截图 | 命名 `<页面>[-<视图>][-<主题>].png`；现有 `home.png`、`file-browser.png` 等页面截图无需强制改名，如 `detail-versions-dark.png` |
| [images/diagrams](images/diagrams/) | 架构图 | **优先用 Mermaid 内嵌在 md 中**；必须位图时优先 SVG |
| [images/demos](images/demos/) | 动图与演示 | 注意仓库体积，必要时外链 |

当前 6 张截图合计约 9.5MB，偏重；建议压缩到 1.5MB 以内或改用 WebP（`cwebp` 本机可用）。

## 文档约定

- **语言**：正文用简体中文；代码标识符、命令、文件路径保持英文。
- **ADR 必须写 `Revisit trigger`**：说明「什么条件下重估这个决策」，避免选型被默认永久化。
- **结论要能被引用**：`Decision` 段一句话说清决定了什么，细节放 `Consequences`。
- **区分事实与假设**：无法在仓库内验证的外部事实（上游组件行为、第三方包状态）标注为假设，并写出验证方式。
- **引用代码用相对路径**：从本文档出发的相对路径 + 可选行号（如 `../../lib/main.dart#L33`），便于随代码演进核对。
- **不打包**：`docs/` 不参与应用打包（`pubspec.yaml` 只声明 `assets/theme_previews/`），文档用图不要放进根 `assets/`。
