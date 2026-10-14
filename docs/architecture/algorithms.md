# 规则、查询策略与算法

本文记录当前代码中的实际策略（2026-10-14），不把框架或后端能力算作项目自研算法。视频解码、音画同步、硬解和 libass 字幕渲染由 libmpv / FFmpeg 等后端提供；项目主要负责解析、匹配、查询与任务协调。

## 扫描与幂等索引

[StorageMediaScanner](../../lib/features/library/infrastructure/storage_media_scanner.dart) 深度优先递归列目录，跳过隐藏项，按扩展名识别视频，并用异步流产出解析后的文件。`LibrarySyncController` 用路径集合统计发现 / 新增，按 128 项批量入库。

扫描完成且无读取错误时，删除该来源“原有路径集合减去本次发现路径集合”对应的索引；扫描出错或退出中断时禁止删除。唯一键 `sourceId:path` 保证重复扫描不会插入重复记录，已有文件属性仍会更新。

遍历工作量随目录项数量增长；递归栈随目录深度增长。虽然文件以流产出，同步控制器仍保存已知 / 已扫描路径集合，内存并非常数；超大目录与异常目录循环需独立验证。

## 文件名解析

[FilenameParser](../../lib/features/library/infrastructure/filename_parser.dart) 使用有优先级的正则与标题清洗：先识别明确季集 / ID 标记，再提取年份、分辨率、编码、声道、HDR、来源，必要时使用父目录补足标题或季号。纯数字集号仅在文件名本身符合规则时采用，避免把年份或分辨率当作集号。

例如 `Example.S01E05.1080p.WEB-DL.mkv` 可提取标题、季号 1、集号 5、1080p 与来源标签。显式 `{tmdbid-123}` 是强匹配提示；提取属性不等于已经成功匹配 TMDB。详细规则见 [媒体流水线](media-pipeline.md#阶段-2文件名解析)。

## 刮削计划与有界并发

[ScrapePlanFactory](../../lib/features/library/application/scrape_plan.dart) 最多构造两次标题搜索：完整清洗标题 + 年份，然后相同标题不带年份；无年份时不重复请求。`MetadataMatchResolver` 优先处理显式 / 已确认 ID，查询结果采用 TMDB 返回的第一个有效对象，项目没有编辑距离或自研模糊评分。

剧集按显式 / 确认 ID 或规范化标题分组，复用剧集 / 季详情请求；不同文件版本仍保留为独立文件。`MetadataScraper` 分电影阶段与剧集分组阶段执行，每阶段最多 5 个异步 worker，领取下一项后等待请求完成。它限制 I/O 并发，不是 5 个 CPU 线程，也不代表有自动重试。

当前网络错误可能被包装成空结果，进一步成为未匹配；应先完善失败分类，再考虑新的相似度算法。

## 本地搜索评分

[normalizeLibrarySearchText](../../lib/core/domain/media/library_search_text.dart) 将文本小写并移除规定的空格 / 分隔符；它不是完整的 Unicode NFKC、拼音或繁简转换。

[LibraryRepository](../../lib/features/library/infrastructure/library_repository.dart) 在 SQL 中对标题 / 原标题取两者评分的最大值：

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
- 首页继续观看在 SQL 中执行，`ContinueWatchingResolver` 保留为领域规则参照并由查询测试比较结果，不承担全库内存投影。
- [PlaybackQueue](../../lib/features/playback/domain/playback_queue.dart) 按 `sourceId:path` 用集合去重并保留输入顺序；上一项 / 下一项通过当前索引和偏移选择。剧集的输入顺序来自库查询。

领域续播选择包含排序，通常为 O(n log n)；队列去重为期望 O(n)，索引选项为 O(1)。SQL 窗口函数与关联子查询的实际成本取决于数据分布、索引和执行计划，不能直接套用领域实现的复杂度。

## 进度与窗口任务顺序

[PlaybackResumePolicy](../../lib/features/playback/domain/playback_resume_policy.dart) 对未完成位置回退 5 秒，裁剪到 0；位置为 0 或已达时长 95% 时不续播。数据库更新同时推导观看状态，两个位置的阈值目前需同步维护。

周期保存每 10 秒触发，位移不足 5 秒时跳过；切集、完成、关闭等强制保存绕过阈值。[PlaybackProgressWriter](../../lib/features/playback/application/playback_progress_writer.dart) 按接受顺序串行写入，失败保留给调用方，但不阻断后续队列；关闭前等待已接受写入，减少旧快照覆盖新位置的风险。

`PlayerWindowCoordinator` 同样串行处理窗口创建 / 请求替换；退出开始后拒绝新请求，已接受操作仍由退出流程收尾。超时退出是有界资源管理策略，不保证最后进度一定落库，详见 [播放生命周期](playback.md#生命周期与退出)。
