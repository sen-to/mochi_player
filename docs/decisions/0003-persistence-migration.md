# 0003 持久化：Isar 3 迁往 drift + SQLite

- **Status**: Proposed
- **Date**: 2026-10-05
- **Related**: [0001 多窗口策略](0001-multi-window-strategy.md)

## Context（背景与约束）

当前实现：`isar 3.1.0+1` + `isar_flutter_libs` + `isar_generator`，6 个 collection
（[entities/](../../lib/core/infrastructure/database/entities/entities.dart)），生成物 `*.g.dart` 已提交入库。

上游状态（**事实与假设**：本节关于上游发布节奏的结论来自公开社区信号，撰写环境无法直连 pub.dev 核对精确发布日期，落地前应复核）：

- pub.dev 上 `isar` 的最新稳定版仍是本项目在用的 `3.1.0+1`（2023 年年中前后），此后没有新的稳定发布；v4 长期停留在「计划中」。
- 社区已出现明确的替代信号：[Isar is dead, long live Isar #1689](https://github.com/isar/isar/issues/1689)、[Is v4 still planned? #1735](https://github.com/isar/isar/discussions/1735)。
- 维护由社区 fork 承接：`isar_community` 已迭代到 [3.3.x](https://pub.dev/packages/isar_community/changelog)，主要在处理新工具链兼容（如 AGP 8.x、版本求解）。

项目内已出现的摩擦：

1. 生成物必须整目录排除出静态分析（[analysis_options.yaml](../../analysis_options.yaml) 注释：Isar 3 生成的兼容代码被 Flutter 3.47 判为 experimental）；
2. 改实体 → `build_runner` → 生成物入库，**没有任何 schema 版本化与迁移机制**；
3. 媒体库列表主要采用「全量读出 + 内存真源」：`MediaLibraryCatalog` 从 `getAll*` 加载媒体文件与元数据，再在内存中筛选和聚合；刮削进度回调还会反复全量拉取季与集（[database_service.dart:106-234](../../lib/core/infrastructure/database/database_service.dart#L106-L234)、[library_sync_controller.dart:275-291](../../lib/features/library/application/library_sync_controller.dart#L275-L291)）。`DatabaseService` 也提供按键、收藏筛选和限量排序等查询，故问题在于主要列表路径未使用数据库查询能力，而非所有读取都全表扫描；
4. **多引擎写库**：[main.dart:33](../../lib/main.dart#L33) 与 [player_window_app.dart:379](../../lib/features/playback/presentation/player_window_app.dart#L379) 在同一进程内各自 `Isar.open` 同一目录，且子引擎会写播放进度。Isar 3 的设计前提是同进程多 isolate **共享同一实例**，不支持多进程/多连接各开一份。

迁移面（已核实）：仅 8 个文件 import `package:isar/`，`DatabaseService` 是唯一出口（10 个引用点），Isar 特有 API 调用集中在该文件内，且 entity ↔ domain 已由 `MediaEntityMapper` 隔离，UI 层不受影响。

## Decision（决策）

**目标方案：迁移到 drift（基于原生 SQLite），并借迁移之机把数据访问从「全表载入内存」改为「查询 + 订阅」。**

必须遵守的规则：

1. 迁移以 `DatabaseService` 为边界，**保持其公开方法语义不变**，使调用方（library / playback / storage）在迁移期间无需改动；方法签名可按 drift 的异步特性微调，但语义不得变化。
2. 唯一键语义等价：`storageKey = sourceId:path` 必须映射为 SQLite 的 `UNIQUE` 约束，并继续使用「冲突即更新」的写入语义（drift 的 `insertOnConflictUpdate`）。
3. 数据库连接必须支持多连接并发访问：启用 WAL，设置 `busy_timeout`；drift 的 `NativeDatabase` 必须通过 `createInBackground` 放到后台 isolate，避免大查询阻塞 UI。
4. 内嵌结构（`cast`、`genres`、`ArtistEmbedded`）统一用 `TypeConverter` 存 JSON 列，首版不拆子表。
5. 迁移过程中**必须**提供一次性数据搬运（旧 Isar → 新库），保留播放进度、收藏与已刮削元数据；不得以「让用户重新扫描」代替（重扫会丢失 `position` / `lastWatchedAt` / `isFavorite`，并浪费 TMDB 配额）。

过渡选项：若需要在不改动业务代码的前提下快速解除对新 Flutter 的适配阻塞，可先切到 `isar_community 3.3.x`（改包名与 generator 版本），但**仅作为过渡**，不作为终局。

## Consequences（后果）

- **正面**
  - 多引擎/多连接写库从「未定义行为」变为有明确语义与锁机制；
  - 获得索引、join、聚合、分页能力，海报墙与剧集列表不再每次构建全量重算；
  - `.watch()` 流式查询可替换手写的修订号机制（[media_library_catalog.dart:67-80](../../lib/features/library/application/media_library_catalog.dart#L67-L80)）；
  - 版本化迁移 + `drift_dev` schema 快照与迁移测试，替代「改实体即重建」；
  - 数据层测试可用内存库（`NativeDatabase.memory()`），不依赖文件系统；
  - 排障可用任意 SQLite 工具直接打开库文件（当前 Isar 的 Inspector 已随上游停更）。
- **负面**
  - 失去 Isar 的「对象直接入库」便利，内嵌列表需要 JSON 转换或子表；
  - `NativeDatabase` 为同步 API，必须正确处理 isolate（否则大查询会卡 UI）；
  - 安装包新增 sqlite3 动态库（与现有 native 库体量相当）；
  - 一次性数据搬运脚本需要测试覆盖，避免用户进度丢失。
- **跟进**
  - 表定义 6 张 + `DatabaseService` 等价实现 + 迁移测试 + 数据搬运脚本；
  - 迁移完成后再做「查询化」改造（列表、续看、收藏、搜索），并删除 catalog 修订号机制。

## Alternatives（备选与否决理由）

| 备选 | 评价 | 结论 |
| --- | --- | --- |
| `isar_community` 3.3.x | 迁移成本最低（改包名即可），但同样是小规模维护，且**不解决**多连接写库与查询能力问题 | 仅作过渡 |
| `objectbox` | 性能好、公司维护，但桌面端 Dart 支持较弱，多 isolate/进程同样有约束，且不提供 SQL 与迁移测试能力 | 否决 |
| `sembast` / `hive_ce` | 纯 Dart、免 native 依赖，打包友好；但仍是「全量载入内存」的 NoSQL，等于把现有问题原样搬家 | 否决 |
| `realm`（Atlas Device SDK） | MongoDB 已弃用该 SDK 并公布生命周期终止（[官方弃用说明](https://www.mongodb.com/zh-cn/products/updates/product-support-deprecation)） | 否决 |
| 裸 `sqlite3`（不用 drift） | 依赖更少，但要手写 SQL、自行实现迁移与订阅 | 可选；若团队希望减少生成物，可作为备选 |
| `sqflite` | 移动端平台通道实现，桌面需换成 `sqlite3` + `sqlite3_flutter_libs` | 否决 |

## Revisit trigger（重估触发条件）

满足任一条即重新评估：

1. 上游 Isar 发布 v4 且明确恢复维护（有活跃维护者与发布节奏）——此时可重新比较，但仍需解决多连接写库问题；
2. drift 迁移的实测成本超出预估（建议阈值：超过 5 人日，或需要改动 3 个以上业务模块的公开行为）——此时先落 `isar_community` + [0001](0001-multi-window-strategy.md) 的「数据库单写者」改造，把风险压到最低再择机迁移；
3. SQLite 在 macOS/Windows 打包路径上出现不可接受的体积或签名问题。
