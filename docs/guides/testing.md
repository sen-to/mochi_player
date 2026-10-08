# 测试与代码质量

## 现状

- 测试文件约 58 个、合计约 4200 行，目录与 `lib/` 大体对应：
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
- 生成代码与平台目录不参与静态检查：`build/**`、`windows/**`、`macos/**`、`lib/core/infrastructure/database/entities/*.g.dart`。

## 待补

| 项 | 说明 |
| --- | --- |
| 格式检查未进 CI | 建议增加 `dart format --set-exit-if-changed`，避免格式化差异混入评审 |
| 无 macOS CI | macOS 是主要开发平台，但流水线只有 Windows；至少应跑 analyze 与 test |
| 数据层测试方式待更新 | 若按 [0003](../decisions/0003-persistence-migration.md) 迁移到 drift，可用内存数据库（`NativeDatabase.memory()`）替代真实目录 |
| 缺验收清单 | [0002](../decisions/0002-playback-engine.md) 的播放能力表尚未落成可执行的手工验收步骤（HDR、多音轨、字幕样式等难以自动化） |
