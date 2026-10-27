# 媒体库维护地图

媒体库页面和其他功能从 [MediaLibraryProvider](media_library_provider.dart) 查询与操作媒体库。来源配置和文件浏览分别有自己的入口，不经过媒体库查询入口。

## 按要修改的功能找代码

| 要改什么 | 从这里开始 | 接着读哪里 |
| --- | --- | --- |
| 电影 / 剧集列表、收藏、续播、分页 | [catalog/library_repository.dart](catalog/library_repository.dart) | `catalog/library_page.dart`；共享查询组件在 `widgets/library_query.dart` |
| 列表海报、评分和进度样式 | [widgets/media_card.dart](widgets/media_card.dart) | `catalog/media_card_view_data.dart`；下载 / 缓存实现在共享的 `core/infrastructure/tmdb/` |
| 媒体详情、季集、演员 | [detail/media_detail_page.dart](detail/media_detail_page.dart) | 同目录的 `media_detail_header.dart`、`episode_list.dart`、`cast_list.dart` |
| 文件浏览、排序和搜索 | [browser/file_browser_provider.dart](browser/file_browser_provider.dart) | 同目录的 `file_browser_page.dart`、`file_browser_entry.dart` 和列表 / 网格组件 |
| 添加 / 编辑 / 删除来源 | [sources/storage_sources_settings.dart](sources/storage_sources_settings.dart) | 对应的 `local_source_editor.dart`、`smb_source_editor.dart`、`webdav_source_editor.dart`；保存 / 测试入口是 `storage_sources_service.dart` |
| 扫描顺序、分批入库、失效文件清理、退出收尾 | [sync/library_sync_service.dart](sync/library_sync_service.dart) | 同目录的 `library_source_scanner.dart`、`library_sync_repository.dart`；读写实现是 `database_library_sync_repository.dart` |
| 文件名解析和技术信息 | [sync/filename_parser.dart](sync/filename_parser.dart) | `media_file_metadata_mapper.dart` 将解析结果应用到文件快照 |
| 目录遍历、扫描期间的连接释放 | [sync/storage_library_source_scanner.dart](sync/storage_library_source_scanner.dart) | 同文件内的扫描会话和递归扫描实现 |
| 显式 ID、已有 ID、标题 / 年份回退匹配 | [metadata/metadata_matcher.dart](metadata/metadata_matcher.dart) | 候选、搜索计划和匹配结果都在同文件；仅修改策略无需阅读网络或 SQL 实现 |
| 刮削并发、剧集分组、成功 / 失败统计 | [metadata/metadata_scraper.dart](metadata/metadata_scraper.dart) | 输入匹配交给 `MetadataMatcher`；结果与进度类型放在本文件 |
| TMDB 响应 / 错误如何进入刮削 | [metadata/tmdb_metadata_source.dart](metadata/tmdb_metadata_source.dart) | `metadata_source.dart` 定义所需能力；共享 HTTP / JSON 实现在 `core/infrastructure/tmdb/` |
| 元数据和关联的原子导入 | [metadata/database_metadata_repository.dart](metadata/database_metadata_repository.dart) | `metadata_repository.dart` 定义契约；表与共享写入在 `core/infrastructure/database/` |
| 增加存储协议 | 共享的 `core/domain/storage/storage_adapter.dart` | 在 `core/infrastructure/storage/` 实现并注册协议；配置表单位于 `sources/`，扫描编排不判断具体协议 |

## 阅读和依赖规则

- 先打开对应流程目录里的入口，再按实际需要阅读同目录的规则、契约或适配器。目录靠近不表示页面可以直接调用数据库或创建协议连接。
- `sync` 编排通过扫描与持久化契约工作；`metadata` 的匹配、刮削通过元数据获取 / 持久化契约工作。事务、凭据和协议实例留在具体适配器。
- `widgets` 仅放多个媒体库流程共用的 UI；仅用于详情或浏览的组件留在各自流程目录。
- 输入、进度、结果等仅伴随一个流程的类型与其放在同文件。不创建旧路径转发文件或一层层的 barrel 导出。
- 应用组装统一在 [`ApplicationDependencies`](../../app/bootstrap/application_dependencies.dart)，共享数据模型、协议和数据库仍保留在 `core`。

## 验证位置

`test/features/library/` 按相同流程镜像组织：`catalog` 验证查询和 SQL 次数，`browser` 验证浏览，`sources` 验证来源业务与表单，`sync` 验证扫描 / 退出，`metadata` 验证匹配、刮削与事务。文件名解析和搜索计划测试也在对应目录；独立 SQL 搜索评分参考实现仅放在 `test/support/library_search_reference.dart`。

执行方式及已确认的平台范围见 [测试指南](../../../docs/guides/testing.md)。
