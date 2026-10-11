# 测试与代码质量

## 现状

- 测试包含 SQLite 数据层与查询订阅测试，目录与 `lib/` 大体对应：
  - `test/core/**` —— 设计系统组件、存储解析器、TMDB 匹配与映射、格式化的单元与 Widget 测试；
  - `test/features/**` —— 媒体库查询、文件浏览、播放队列与进度写入、设置；
  - `test/app/**` —— 外壳组件。
- 两个测试位于 `test/` 根目录（`filename_parser_test.dart`、`scrape_plan_test.dart`），与镜像结构不一致，属于待整理项。
- 数据层依赖注入到位：`DatabaseService`、`TmdbService`、存储扫描器等都可从构造函数替换，因此多数测试不触碰真实数据库或网络。

## 运行

```bash
fvm flutter test                              # 全部
fvm flutter test test/features/playback       # 指定目录
fvm flutter test --plain-name "解析"          # 按名称筛选
fvm dart format lib test                      # 格式化（120 列，配置见 analysis_options.yaml）
fvm flutter analyze                           # 静态检查
```

提交流程至少运行全量测试、格式化和静态检查；目录与名称筛选命令是按需使用的示例。CI 目前只执行 analyze + test + 构建。

## 约定

- 代码统一 120 列，由 [analysis_options.yaml](../../analysis_options.yaml) 的 `formatter.page_width` 声明，无需传参。
- 导入统一使用包路径（`always_use_package_imports`）。
- 构建与平台目录（`build/**`、`windows/**`、`macos/**`）不参与静态检查；drift 生成代码参与静态检查。

## 待补

| 项 | 说明 |
| --- | --- |
| 格式检查未进 CI | 建议增加 `dart format --set-exit-if-changed`，避免格式化差异混入评审 |
| 无 macOS CI | macOS 是主要开发平台，但流水线只有 Windows；至少应跑 analyze 与 test |
| 缺验收清单 | [0002](../decisions/0002-playback-engine.md) 的播放能力表尚未落成可执行的手工验收步骤（HDR、多音轨、字幕样式等难以自动化） |

## SQLite 数据层

`test/core/infrastructure/database/database_service_test.dart` 使用真实 SQLite 验证唯一键更新、JSON 元数据往返、日期精度、事务回滚、播放进度与收藏的局部写入、来源删除和清理语义。临时文件测试验证两个后台连接的并发写入与关闭后重开。

`test/features/library/application/library_repository_test.dart` 验证 SQL 可用性筛选、分页、Unicode 搜索排序、剧集详情范围、队列、收藏去重、续播与领域策略一致性、订阅失效和刮削候选。旧 Catalog 查询测试和 Entity 映射测试已移除。

修改表定义后执行 `fvm dart run build_runner build`。schema 版本从 1 开始，尚未发布 Release，因此不提供 Isar 旧数据导入；后续 SQLite schema 变更需提升版本并提供版本间迁移测试。
