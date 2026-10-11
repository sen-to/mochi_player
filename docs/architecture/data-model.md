# 数据模型

## 存储分工

| 数据 | 存放位置 | 说明 |
| --- | --- | --- |
| 媒体文件、元数据、播放进度、收藏、媒体源 | drift + SQLite | 应用文档目录的 `mochi_player.sqlite`，六张表 |
| 应用设置 | SharedPreferences | TMDB、缓存、字幕、主题 |
| TMDB 图片 | flutter_cache_manager 文件缓存 | 30 天过期，上限 1200 条 |

[DatabaseService](../../lib/core/infrastructure/database/database_service.dart) 负责连接与写入边界，[LibraryRepository](../../lib/features/library/infrastructure/library_repository.dart) 负责 SQL 读取投影。[AppDatabase](../../lib/core/infrastructure/database/app_database.dart) 定义 typed 表与 schema 版本。生产连接通过 `NativeDatabase.createInBackground` 运行在后台 isolate，启用 WAL、5 秒 busy timeout 和外键检查。当前保留两个窗口分别建立连接的方案；单写者仅在实测并发问题或统一状态管理需求出现时评估，见 [0001](../decisions/0001-multi-window-strategy.md)。

项目尚无 Release，本次从 Isar 替换后直接建立新库，不导入或删除旧库；需重新配置媒体源与扫描，见 [0003](../decisions/0003-persistence-migration.md)。

## 表与唯一键

| 表定义 | 业务唯一键 | 内容 |
| --- | --- | --- |
| `MediaFiles` | `storageKey = sourceId:path` | 路径、文件名、解析结果、独立电影 / 剧集 / 单集 ID、匹配状态、技术标签、进度、收藏 |
| `Movies` | `tmdbId` | 电影标题、日期、图片、简介、评分、分级、类型、演员 |
| `TVShows` | `tmdbId` | 剧集元数据、状态与季集数量 |
| `Seasons` | `seasonKey` | `show_s1` 形式的季身份、标题、简介、海报 |
| `Episodes` | `tmdbId` | `show_s1e1` 形式的单集身份、集号、标题、日期、剧照、客串演员 |
| `StorageSources` | `sourceId` | 名称、类型、地址、根路径、启用状态与凭据 |

媒体文件与来源有自增整数 ID；冲突更新保留 ID。电影、剧集、季和集直接使用业务键作为主键。媒体文件按来源、显式 / 已确认 TMDB ID、观看状态、最近观看时间、收藏与添加时间建立索引。

当前季与集的关联继续由已有 ID 约定推导，不建立外键关系；原 Isar Link / Backlink 未被应用使用，已移除。

## 编码与映射

- drift `@UseRowClass` 直接构造不可变领域模型，并生成 `toInsertable()`。旧 Entity、Stored 枚举与两层手写映射已删除；只有媒体源配置使用生成的 `StorageSourceRow` 经仓库转换。
- 类型与演员列表由 [JSON 转换器](../../lib/core/infrastructure/database/json_converters.dart) 存入 TEXT 列。
- 枚举存名称，避免枚举排序变更改变数据含义；日期使用 ISO 文本，保留微秒精度（`build.yaml`）。
- `MediaFile.tmdbId` 仍表示可直接播放项：电影取 `movieTmdbId`，单集取 `episodeTmdbId`，所属剧集单独使用 `tvShowTmdbId`。

## 进度、收藏与事务

`updateProgress` 裁剪位置、可选更新时长并写入观看时间：位置为 0 为未开始，达到时长 95% 为已完成，其余为观看中。95% 也用于续播策略，修改时需同步。

扫描只更新文件属性；类型变更时在 SQL 中清空不兼容的匹配关系。刮削只更新匹配关系，进度和收藏各自使用局部 SQL UPDATE，旧快照不会覆盖用户状态。扫描按 128 个文件分批提交，季集导入使用 batch；元数据与对应匹配在事务内提交。删除来源保留共享元数据；`clearLibrary` 保留媒体源配置。

列表搜索、收藏与续播目标先在 SQL 中筛选、排序、聚合和 LIMIT，再返回页面投影。网格初始读取 100 条，滚动时按 100 条扩展；首页只保存 15 条最近添加、15 条续播和 1 条 Hero 候选。详情与播放队列按标题查找，已移除全量内存 Catalog 与修订号。查询在当前连接自动订阅变更；播放器回传变更键后显式使主窗口查询失效。

## 设置与凭据

[AppSettingsService](../../lib/features/settings/infrastructure/app_settings_service.dart) 使用 SharedPreferences 保存 TMDB Key / 地址 / 代理、缓存、预读、硬件解码、字幕语言与样式。主题由 `ThemeProvider` 保存。

媒体源用户名与密码仍是 SQLite 普通文本字段，尚未接入系统钥匙串；此次存储替换不改变其安全边界。跨窗口参数不传凭据。

## Schema 与测试

schema 版本从 1 开始，表定义变更后执行 `fvm dart run build_runner build`。生成代码与 `drift_schemas/` 初始快照提交入库；导出初始快照的命令为 `fvm dart run drift_dev schema dump lib/core/infrastructure/database/app_database.dart drift_schemas/`。后续 schema 变更需增加版本、迁移策略与迁移测试。

数据层测试使用内存 SQLite 与临时文件的两个后台连接，覆盖唯一键、JSON、日期、事务、局部更新和持久化。

## 待改进

- 删除文件后元数据尚未回收。
- 主窗口关闭时需协调播放器最后进度提交，再关闭连接并退出进程；该退出流程尚待实现。
- 独立连接不自动共享失效通知；现有回传事件用于播放结束或切换后的刷新，播放过程实时同步需扩展协议。
