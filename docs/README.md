# Mochi Player 开发文档

面向用户的功能、安装、快捷键和限制放在根 [README](../README.md)。本目录说明开发者需要理解的实现、决策、操作和验证边界。

## 建议阅读顺序

1. [当前实施状态](status.md)：哪些已实现、哪些只是已接受的计划、哪些尚待验证。
2. [架构总览](architecture/overview.md)：系统数据流、分层职责、实际调用路径、已落实的职责边界与资源所有权。
3. [数据模型](architecture/data-model.md) → [媒体流水线](architecture/media-pipeline.md) → [播放](architecture/playback.md)：按实际调用链理解代码。
4. [算法说明](architecture/algorithms.md)：文件解析、搜索评分、续播、任务调度及复杂度边界。
5. [测试指南](guides/testing.md) 与对应平台构建指南：复现、验收和排障。
6. 修改技术方向前阅读相关 ADR。

## 文档分工

| 类型 | 回答的问题 | 维护方式 |
| --- | --- | --- |
| `status.md` | 已决定 / 已实现 / 尚待验证什么？ | 功能阶段变化时更新，引用验证证据 |
| `architecture/` | 当前代码如何运行？ | 实现变化时更新，不混入未来接口作为现状 |
| `decisions/` | 为什么这样设计，什么时候重估？ | 保留决策背景，明确当前实施状态 |
| `guides/` | 如何运行、测试、构建和排障？ | 命令和验收步骤保持可执行 |
| `history/` | 当时验证了什么，原型提供了什么证据？ | 保留历史 SDK、素材与验证边界，不作为当前操作指南 |

## 架构与指南索引

| 文档 | 内容 |
| --- | --- |
| [架构总览](architecture/overview.md) | 分层职责、统一命名约定、依赖作用域、实际业务调用及运行时资源 |
| [数据模型](architecture/data-model.md) | 六表完整字段字典、类型 / 主外键 / 约束 / 索引、设计取舍、ORM 与读写边界 |
| [媒体流水线](architecture/media-pipeline.md) | 扫描、文件名解析、TMDB 刮削、错误边界与索引展示 |
| [播放](architecture/playback.md) | 请求、目标解析、引擎门面、mini / 全屏、退出时序、字幕与进度 |
| [算法说明](architecture/algorithms.md) | 项目规则与 SQL 策略，区分后端能力与自研实现 |
| [macOS 构建](guides/build-macos.md) | CocoaPods / SPM、沙箱、标题栏、原生插件警告 |
| [Windows 构建](guides/build-windows.md) | 单引擎宿主、原生扩展、固定 SDK CI、构建与运行时边界 |
| [测试与验收](guides/testing.md) | 测试分工、当前结果、真实窗口冒烟和手工清单 |
| [验证历史](history/validation-2026-10.md) | 2026 年 10 月各轮验证的原始上下文 |
| [官方多窗口原型](history/official-single-engine-windowing.md) | 历史实验、SDK / Release 证据及适用边界 |

## 决策记录

| 编号 | 决策 | 状态 |
| --- | --- | --- |
| [0001](decisions/0001-multi-window-strategy.md) | 官方单引擎多视图、mini、主窗口关闭即退出 | Accepted |
| [0002](decisions/0002-playback-engine.md) | libmpv 经 media_kit 接入，PlaybackEngine 门面 | Accepted |
| [0003](decisions/0003-persistence-migration.md) | drift + SQLite 与新库迁移边界 | Accepted |
| [0004](decisions/0004-i18n-l10n.md) | gen-l10n / ARB、应用内语言切换 | Accepted |
| [0005](decisions/0005-smb-playback-path.md) | SMB 本地 HTTP 回源方向 | Accepted，回源尚未实现 |
| [0006](decisions/0006-media-server-integration.md) | 独立媒体服务器层，Emby 优先 | Accepted，适配器尚未实现 |

`Accepted` 表示决策已接受，不等于功能已交付；`Proposed` 表示待确认；`Superseded by NNNN` 表示已被其他 ADR 替代。新决策从 [模板](decisions/0000-template.md) 开始，必须写重估条件。

## 维护约定

- 正文使用简体中文，代码标识、路径和命令保持原文；代码引用用从文档出发的相对链接。
- 变更实现时同步受影响的架构、ADR 实施状态和 `status.md`；验证结果只在测试指南汇总，逐轮细节进入历史记录。
- 图优先使用 Markdown 内嵌 Mermaid，注明箭头代表导入、数据流还是逻辑关系；不能画出代码尚未声明的 SQL 外键约束。
- 外部能力附来源与核对范围；假设、计划、构建结果、原生运行和人工确认分别表述，不扩大证据范围。
- 文档不参与应用打包。产品截图放 `images/screenshots/`，其他素材目录按实际需要创建。优先控制图片体积，不把缓存、测试视频和生成日志提交到仓库。
