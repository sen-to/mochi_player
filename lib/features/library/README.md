# 媒体库维护地图

先按功能流程找入口，再按统一职责目录找代码：`ui` 是界面，`application` 是 Provider、用例和能力契约，`domain` 是业务模型与规则，`data` 是数据库或外部服务适配。没有独立服务器后端，SQLite、网络和协议访问属于数据层。

## 入口与数据流

```text
application/media_library_provider.dart   媒体库共享状态与操作入口
browser/application/file_browser_provider.dart  文件浏览状态与连接协调
sources/application/storage_sources_service.dart 来源保存、删除与测试入口
sync/application/library_sync_service.dart       扫描与刮削总流程
metadata/application/metadata_scraper.dart        受限并发与文件级统计
metadata/application/metadata_matcher.dart        ID 与标题匹配用例
```

界面调用这些入口；入口依赖应用契约及领域模型。`data` 实现契约，实例由 `app/bootstrap` 注入。数据库只生成 DO，数据 Mapper 转为业务模型；展示 Mapper 再生成 VO，UI 不理解数据库记录。

## 按修改任务定位

| 要改什么 | 入口 | 相关职责 |
| --- | --- | --- |
| 列表、收藏、续播、分页、SQL 开销 | [目录数据库实现](catalog/data/library_catalog_repository_impl.dart) | [目录契约](catalog/application/library_catalog_repository.dart)、[媒体库 Provider](application/media_library_provider.dart)、[目录页面](catalog/ui/library_page.dart) |
| 卡片字段和格式 | [卡片 Mapper](catalog/application/media_card_mapper.dart) | [卡片 VO](catalog/application/media_card_vo.dart) 只保存数据；[卡片界面](ui/widgets/media_card.dart) 只负责渲染 |
| 详情字段与布局 | [详情页面](detail/ui/media_detail_page.dart) | [详情 Mapper](detail/ui/media_detail_mapper.dart)、[详情 VO](detail/ui/media_detail_vo.dart) 和同目录组件 |
| 浏览、排序、过滤、连接切换 | [浏览 Provider](browser/application/file_browser_provider.dart) | [条目模型](browser/domain/file_browser_entry.dart)、[浏览界面](browser/ui/file_browser_page.dart) |
| 新增、编辑、删除来源 | [来源服务](sources/application/storage_sources_service.dart) | [来源面板](sources/ui/storage_sources_panel.dart) 与 `*_source_dialog.dart`；共享持久化契约及实现分别位于 core/domain、core/data |
| 版本选择与播放请求 | [媒体库播放入口](ui/library_playback_launcher.dart) | 媒体库完成版本与队列查询后提交请求，播放功能不反向导入媒体库 |
| 扫描顺序、分批入库、失效清理、退出 | [同步服务](sync/application/library_sync_service.dart) | [扫描契约](sync/application/library_source_scanner.dart)、[持久化契约](sync/application/library_sync_repository.dart)、[数据库适配](sync/data/library_sync_repository_impl.dart) |
| 文件名解析与本地属性 | [文件名解析规则](sync/domain/media_filename_parser.dart) | [解析结果模型](sync/domain/parsed_media_filename.dart)、[扫描文件 Mapper](sync/application/scanned_media_file_mapper.dart) |
| 遍历目录与释放扫描连接 | [存储扫描适配](sync/data/storage_library_source_scanner.dart) | 会话封装凭据和连接；不完整扫描报告读取失败，不清除旧索引 |
| 候选输入与 ID / 标题匹配 | [匹配用例](metadata/application/metadata_matcher.dart) | [候选模型](metadata/domain/scrape_candidate.dart) 直接引用原始文件，字段不重复保存、[搜索计划规则](metadata/domain/scrape_search_plan.dart) |
| 刮削并发、分组与统计 | [刮削用例](metadata/application/metadata_scraper.dart) | [匹配结果模型](metadata/domain/metadata_match.dart)、[搜索计划模型](metadata/domain/scrape_search_plan.dart)；请求错误不等同于未匹配 |
| TMDB 结果与错误 | [TMDB 数据适配](metadata/data/tmdb_metadata_source.dart) | [获取契约](metadata/application/metadata_source.dart)；共享 JSON Mapper 只留在 core/data |
| 元数据与关联的原子导入 | [元数据数据库适配](metadata/data/metadata_repository_impl.dart) | [持久化契约](metadata/application/metadata_repository.dart)；DO 与业务模型通过 core/data/database/mappers 转换 |

## 约束与验证

- Provider 不导入具体数据实现；新增数据库或协议实现只在组装处选择。
- 业务规则只消费业务类型；原始 JSON、DO 和第三方 SDK 类型不能进入 Provider 或 UI。
- 来源变更后的浏览失效、设置生效后的首页刷新由应用入口连接，不由表单或页面自行协调其他功能。
- 共享组件只放 `library/ui/widgets`；跨功能通用图片资源经 `core/ui/images`，功能页面不接触具体缓存实现。
- 独立 SQL 搜索和续播参考实现只位于 `test/support`。测试按实际职责放在 `test/features/library`，不新增旧路径导出或兼容别名。

完整规则见 [编码指南](../../../docs/guides/code-organization.md)，命令与证据见 [测试指南](../../../docs/guides/testing.md)。
