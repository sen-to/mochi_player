# 开发文档

用户功能、安装与快捷键见根 [README](../README.md)。开发者先读 [实施状态](status.md)，再按任务选择下列文档。

## 从哪里开始

| 任务 | 阅读入口 |
| --- | --- |
| 修改媒体库具体功能 | [媒体库维护地图](../lib/features/library/README.md)：按查询、详情、来源、浏览、扫描、匹配定位文件 |
| 修改播放具体功能 | [播放维护地图](../lib/features/playback/README.md)：按入口、会话、字幕、控制栏和窗口定位文件 |
| 了解系统与调用链 | [架构总览](architecture/overview.md) |
| 本轮维护性审查 | [全仓维护审查记录](history/maintainability-2026-10-27.md)：检查范围、合并依据与验证限制 |
| 分清界面、状态与业务 | [编码指南](guides/code-organization.md#目录骨架)：ui、application（Provider / 用例 / 契约）、domain、data；手写文件开头有中文职责说明 |
| 新增或修改代码 | [代码组织与新增功能](guides/code-organization.md)：目录、命名、依赖与评审规则 |
| 修改数据库 | [数据模型](architecture/data-model.md)：完整字段、主外键、约束、索引与迁移 |
| 修改扫描 / 刮削 | [媒体流水线](architecture/media-pipeline.md)、[算法说明](architecture/algorithms.md) |
| 修改播放 / 窗口 | [播放](architecture/playback.md)：目标解析、SMB 回源、资源所有权与退出 |
| 修改语言 / 文案 | [本地化](architecture/localization.md) |
| 构建与排障 | [macOS](guides/build-macos.md)、[Windows](guides/build-windows.md) |
| 运行检查 / 验收 | [测试指南](guides/testing.md) |
| 查设计依据 | 下方 ADR 索引；旧验证与排障见 [验证历史](history/validation-2026-10.md) |

## 文档职责与更新规则

每类事实只在一个位置维护，其他文档通过链接引用：

| 文档 | 负责的内容 | 何时修改 |
| --- | --- | --- |
| `status.md` | 当前完成度、待验收范围与待办 | 实施阶段或验收状态变化 |
| `architecture/` | 当前实现的机制、调用、数据与资源边界 | 机制或接口变化 |
| `guides/code-organization.md` | 后续编码的目录骨架、命名与依赖规则 | 开发约定变化 |
| 其他 `guides/` | 可执行命令、平台适配说明、测试覆盖与最近验证证据 | 操作方式或验证记录变化 |
| `decisions/` | 决策背景、约束、取舍和重估条件 | 技术方向或约束变化 |
| `history/` | 阶段验证证据、关键故障与历史选型依据 | 归档有追溯价值的结论时，合并重复过程记录 |
| 根 `README.md` | 面向用户的功能、限制、安装与最短运行路径 | 用户可见行为或使用方式变化 |

普通实现变更只更新受影响的机制与测试说明，不要求逐篇修改 ADR。功能阶段变化更新 `status.md`；ADR 的 `Accepted` 是决策状态，不随单次测试结果变化。测试数量、成功标记与平台证据集中在 [测试指南](guides/testing.md#验证基线)，旧记录移入历史，不反复抄写到各文档。

## ADR 索引

| 编号 | 决策 |
| --- | --- |
| [0001](decisions/0001-multi-window-strategy.md) | 官方单引擎多视图、mini、主窗口关闭即退出 |
| [0002](decisions/0002-playback-engine.md) | libmpv 经 media_kit 接入，PlaybackEngine 门面 |
| [0003](decisions/0003-persistence-migration.md) | drift + SQLite 与开发库数据边界 |
| [0004](decisions/0004-i18n-l10n.md) | gen-l10n / ARB 与应用内语言切换 |
| [0005](decisions/0005-smb-playback-path.md) | SMB 本地 HTTP 回源 |
| [0006](decisions/0006-media-server-integration.md) | 独立媒体服务器层，Emby 优先 |
| [0007](decisions/0007-unified-module-boundaries.md) | 统一职责目录、模型边界与依赖方向 |

`Accepted` 表示已接受，不代表已经实现或验收；`Proposed` 表示待确认；`Superseded by NNNN` 表示已被替代。新决策使用 [模板](decisions/0000-template.md)。尚未实现的方案仅保留在决策 / 计划中，不画成当前架构。

## 写作约定

- 正文用简体中文，路径与代码标识保留原文；代码引用使用相对链接。
- 面向所有项目读者直接说明需求、约束与结论，不写“用户要求”“按要求”或对话轮次；验证记录注明自动检查、日志或人工反馈等证据来源。
- 当前实现文档直接描述工作方式、接口与边界，不夹带旧方案、删除清单或重构过程；选型取舍放 ADR，实施沿革放 `history/`。
- 图使用内嵌 Mermaid，注明箭头含义，区分模块归属、导入与运行时数据流。
- 保留字段字典、协议语义和资源关闭顺序等必要细节；用链接替代重复的大段说明。
- 外部结论附来源及核对日期；区分构建、隔离冒烟、真实环境与人工确认，不扩大证据范围。
- 历史验证按阶段合并，保留日期、提交 / 环境、结果与证据边界；故障保留原因、处理及被推翻的结论。不重复归档整篇实现说明、已完成计划或现行验收清单。
- 文档不参与应用打包；截图放 `images/screenshots/`。不提交缓存、日志或测试视频，不创建空素材目录。
