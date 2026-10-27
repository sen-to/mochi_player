# 规则、查询策略与算法

本文记录当前代码中的实际策略（2026-10-14），不把框架或后端能力算作项目自研算法。视频解码、音画同步、硬解和 libass 字幕渲染由 libmpv / FFmpeg 等后端提供；项目主要负责解析、匹配、查询与任务协调。

## 扫描与幂等索引

扫描清理采用集合差：原有路径减去本次发现路径；读取失败或退出中断时禁止删除。`(sourceId, path)` 唯一约束保证重复扫描幂等，入库与字段更新步骤见 [媒体流水线](media-pipeline.md#阶段-1扫描与入库)。

深度优先遍历的工作量随目录项数量增长，递归栈随目录深度增长。虽然文件以异步流产出，控制器仍保存已知 / 已扫描路径集合，内存并非常数；超大目录与异常目录循环需单独验证。

## 文件名解析

[MediaFilenameParser](../../lib/features/library/sync/domain/media_filename_parser.dart) 按优先级提取季集、显式 ID 和技术信息，并清洗标题；完整规则与示例集中在 [媒体流水线](media-pipeline.md#阶段-2文件名解析)。解析属性不等于成功匹配 TMDB。

## 刮削计划与有界并发

[ScrapeSearchPlan.forCandidate](../../lib/features/library/metadata/domain/scrape_search_plan.dart) 最多构造两次标题搜索：完整清洗标题 + 年份，然后相同标题不带年份；无年份时不重复请求。`MetadataMatcher` 优先处理显式 / 已确认 ID，查询结果采用 TMDB 返回的第一个有效对象，项目没有编辑距离或自研模糊评分。

剧集按显式 / 确认 ID 或规范化标题分组，复用剧集 / 季详情请求；不同文件版本仍保留为独立文件。`MetadataScraper` 分电影阶段与剧集分组阶段执行，每阶段最多 5 个异步 worker，领取下一项后等待请求完成。它限制 I/O 并发，不是 5 个 CPU 线程，也不代表有自动重试。

请求错误与无匹配分开处理；失败不触发标题回退或清除原关联，当前没有自动重试 / 退避。具体传播和季级隔离见 [媒体流水线](media-pipeline.md#请求失败与未匹配)。

## 本地搜索评分

[normalizeLibrarySearchText](../../lib/core/domain/media/library_search_text.dart) 将文本小写并移除规定的空格 / 分隔符；它不是完整的 Unicode NFKC、拼音或繁简转换。

[LibraryCatalogRepository](../../lib/features/library/catalog/data/database_library_catalog_repository.dart) 在 SQL 中对标题 / 原标题取两者评分的最大值：

| 匹配 | 标题得分 | 原标题得分 |
| --- | --- | --- |
| 完全相等 | 120 | 110 |
| 前缀匹配 | 100 | 90 |
| 包含匹配 | 80 | 70 |
| 无匹配 | 0 | 0 |

例如搜索 `example`：标题 `Example` 优先于 `Example Two`，后者优先于 `My Example`。同分用稳定业务键排序；最近添加列表另优先按添加时间排序。使用 `instr` 与规范化函数，不是全文检索或索引支持的模糊搜索；性能按实际数据规模验证。

## 收藏、续播与播放队列

- 收藏查询用 `ROW_NUMBER() OVER (PARTITION BY group_key ...)` 先选每标题代表，再应用排序与 LIMIT，避免多个版本挤占列表。
- 继续观看查询先选每标题最近活动；剧集未完成则续播，已完成则找后续未完成的单集，跳过同集其他版本；没有后续目标的剧集不进入继续观看。
- [EpisodePlaybackTargetResolver](../../lib/core/domain/media/episode_playback_target_resolver.dart) 在剧集播放入口按季 / 集 / 路径排序选择目标；显式播放允许从首个未完成项开始或全部完成后重播。
- 首页继续观看在 SQL 中执行；查询测试用 [LibraryContinueWatchingReference](../../test/support/library_continue_watching_reference.dart) 比较结果，参考实现仅用于测试。
- 普通标题、收藏与续播仅为 SQL 已选出的当前页批量补齐元数据：电影 / 剧集 ID 分开去重，每批最多 400 个，按类型和 ID 回填并保持原 SQL 顺序。卡片组装不执行数据库查询，不跨刷新缓存元数据；原有表订阅继续触发更新。100 条已匹配的混合卡片需要 1 次列表查询 + 2 次元数据查询，只有一种类型时共 2 次，无关联元数据时仅 1 次；扩展页按 400 个 ID 分批增加查询。
- [PlaybackQueue](../../lib/features/playback/domain/playback_queue.dart) 按 `sourceId:path` 用集合去重并保留输入顺序；上一项 / 下一项通过当前索引和偏移选择。剧集的输入顺序来自库查询。

领域续播选择包含排序，通常为 O(n log n)；队列去重为期望 O(n)，索引选项为 O(1)。SQL 窗口函数与关联子查询的实际成本取决于数据分布、索引和执行计划，不能直接套用领域实现的复杂度。

## 进度与窗口任务顺序

[PlaybackProgressWriter](../../lib/features/playback/application/playback_progress_writer.dart) 按接受顺序串行写入，防止旧快照覆盖新位置。失败返回调用方，但不阻断后续队列；关闭前等待已接受写入。保存周期、位移阈值及续播规则见 [播放](playback.md#进度与续播)。

`PlayerWindowCoordinator` 同样串行处理创建 / 替换；退出时拒绝新请求并收尾已接受操作。超时只保证有界结束，不保证最后进度落库，详见 [播放生命周期](playback.md#生命周期与退出)。
