# 数据模型

## 存储分工

| 数据 | 存放位置 | 说明 |
| --- | --- | --- |
| 媒体文件索引、元数据、播放进度、收藏、媒体源配置 | Isar（应用文档目录） | 6 个 collection，见下 |
| 应用设置（TMDB、缓存、字幕、主题） | SharedPreferences | 见「设置键」 |
| TMDB 图片 | 文件缓存（`flutter_cache_manager`） | 30 天过期，上限 1200 条，走与 API 相同的代理配置 |

数据库在 `DatabaseService.init()`（[database_service.dart:29](../../lib/core/infrastructure/database/database_service.dart#L29)）一次性打开全部 collection，集中在一个单例中。

## Isar collection

### `MediaFileEntity` —— 物理媒体文件

[media_file_entity.dart](../../lib/core/infrastructure/database/entities/media_file_entity.dart)

| 分组 | 字段 | 索引 / 说明 |
| --- | --- | --- |
| 标识 | `sourceId` | 索引；所属媒体源 |
| | `storageKey` | **唯一索引**，取值 `sourceId:path`，重扫幂等的关键 |
| | `path` | 相对媒体源根的路径 |
| | `fileName` | 原始文件名 |
| 解析结果 | `parsedTitle` / `parsedYear` / `parsedSeason` / `parsedEpisode` / `mediaType` | 供 TMDB 搜索；`mediaType` 见枚举 |
| 元数据关联 | `explicitTmdbId` | 索引；来自路径中的 `{tmdbid-12345}` |
| | `movieTmdbId` | 索引；电影文件确认的 TMDB ID |
| | `tvShowTmdbId` | 索引；剧集文件所属剧集 ID |
| | `episodeTmdbId` | 索引；剧集文件确认的集 ID |
| | `metadataMatchStatus` | 待匹配 / 已匹配 / 未匹配 |
| 技术信息 | `size` / `container` / `width` / `height` / `videoCodec` / `audioCodec` / `audioChannels` / `isHdr` / `hdrFormat` / `versionLabel` | 由文件名解析得到（非媒体探测） |
| 播放状态 | `duration` / `position` | 毫秒 |
| | `watchStatus` | 索引；未开始 / 观看中 / 已完成 |
| | `lastWatchedAt` | 索引；用于「继续观看」排序 |
| 用户状态 | `isFavorite` / `addedAt` | 索引 |

历史上 movie / tv / episode 共用一个关联字段，无法区分「确认的集」与「剧集级兜底」，现已拆成上面三个独立字段——改动实体后需要重新生成 Isar 代码（`fvm dart run build_runner build --delete-conflicting-outputs`）。

### 元数据 collection

| Collection | 唯一键 | 主要内容 |
| --- | --- | --- |
| `MovieMetadataEntity` | `tmdbId` | 标题、原始标题、上映年份/日期、海报/背景/Logo、简介、评分、类型、演员（内嵌） |
| `TVShowMetadataEntity` | `tmdbId` | 同上（首播日期替代上映日期） |
| `SeasonMetadataEntity` | `seasonKey` | 隶属于某剧集的季，含季海报与简介 |
| `EpisodeMetadataEntity` | `tmdbId` | 集标题、简介、播出日期、剧照、集号；ID 形如 `show_s1e1` |

### `StorageSourceEntity` —— 媒体源配置

[storage_source_entity.dart](../../lib/core/infrastructure/database/entities/storage_source_entity.dart)：`sourceId`（唯一索引）、`name`、`type`、`endpoint`、`rootPath`、`enabled`、`username`、`password`。

凭据当前以**明文**存于同一行（文件注释已注明）。跨窗口只传 `sourceId`，凭据不进入播放器窗口参数，但明文存储本身是待改进项（见 [0003](../decisions/0003-persistence-migration.md) 的后续范围）。

### 枚举

| 枚举 | 取值 |
| --- | --- |
| `StoredMediaType` | movie / episode / unknown |
| `StoredMetadataMatchStatus` | pending / matched / unmatched |
| `StoredWatchStatus` | notStarted / watching / completed |

## 领域模型与映射

`core/domain/media` 定义 `MediaFile`、`Movie`、`TVShow`、`Season`、`Episode`、`Artist`、`LibraryItem` 等不可变模型；
[media_entity_mapper.dart](../../lib/core/infrastructure/database/media_entity_mapper.dart) 负责与实体互转，UI 与业务只接触领域模型。

`MediaFile.tmdbId` 是**可直接播放项**的 ID：电影取 `movieTmdbId`，剧集取 `episodeTmdbId`；所属剧集 ID 单独存于 `tvShowTmdbId`。这一区分由「继续观看」与详情页依赖。

## 进度与观看状态的推导

写入集中在 [database_service.dart:130](../../lib/core/infrastructure/database/database_service.dart#L130) 的 `updateProgress`：

1. 可选更新时长；
2. 位置裁剪到 `[0, duration]`；
3. 写入 `lastWatchedAt = now`；
4. 推导 `watchStatus`：位置为 0 → 未开始；`duration > 0` 且位置 ≥ 95% → 已完成；否则 → 观看中。

95% 这个阈值目前同时出现在播放端的续播策略与库端的状态推导中（[playback_resume_policy.dart](../../lib/features/playback/domain/playback_resume_policy.dart)），是一致的，但属于隐式耦合，改动时需同时修改。

## 设置键（SharedPreferences）

[app_settings_service.dart](../../lib/features/settings/infrastructure/app_settings_service.dart)：

`tmdb_api_key`、`tmdb_api_base_url`、`tmdb_proxy_url`、`tmdb_proxy_enabled`、`playback_cache_size_mb`、`playback_readahead_seconds`、`enable_hardware_acceleration`、`subtitle_language_priority`、`subtitle_font_size`。

主题另由 `ThemeProvider` 使用 `_themePrefKey` / `_accentPrefKey`（存枚举序号）。设置保存时会做范围裁剪（缓存 16–4096 MB、预读 5–1800 秒、字幕 18–40）。

## 已知问题

| 问题 | 说明 |
| --- | --- |
| 无迁移机制 | 改实体即重建，没有版本化迁移；生成物入库并排除出静态分析 |
| 已入库记录不刷新 | 扫描命中唯一键即跳过，`size` / `versionLabel` 等长期不更新 |
| 元数据不回收 | 删除文件只删 `MediaFileEntity`，元数据行残留 |
| 媒体库查询以全量加载为主 | 列表主要从 `getAll*` 装入 `MediaLibraryCatalog` 后在内存筛选与聚合；`DatabaseService` 另有按键、收藏筛选和限量排序查询，但尚未成为主要列表路径 |
| 多引擎写库 | 同一进程两个数据库实例，见 [0001](../decisions/0001-multi-window-strategy.md) |

前三与第五项的处置见 [0003](../decisions/0003-persistence-migration.md)。
