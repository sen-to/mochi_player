# 测试与代码质量

## 现状

- 测试包含 SQLite 数据层与查询订阅测试，目录与 `lib/` 大体对应：
  - `test/core/**` —— 设计系统组件、存储解析器、TMDB 匹配与映射、格式化的单元与 Widget 测试；
  - `test/features/**` —— 媒体库查询、文件浏览、播放队列与进度写入、设置；
  - `test/app/**` —— 外壳组件、应用退出协调与退出时的 SQLite 持久化。
- 两个测试位于 `test/` 根目录（`filename_parser_test.dart`、`scrape_plan_test.dart`），与镜像结构不一致，属于待整理项。
- 数据层依赖注入到位：`DatabaseService`、`TmdbService`、存储扫描器等都可从构造函数替换，因此多数测试不触碰真实数据库或网络。

## 运行

```bash
fvm dart run tool/check_l10n.dart              # 文案完整性
fvm flutter gen-l10n                          # 生成本地化代码
fvm flutter test                              # 全部
fvm flutter test test/features/playback       # 指定目录
fvm flutter test --plain-name "解析"          # 按名称筛选
fvm dart format lib test tool                      # 格式化（120 列，配置见 analysis_options.yaml）
fvm flutter analyze                           # 静态检查
```

提交流程至少运行全量测试、格式化和静态检查；目录与名称筛选命令是按需使用的示例。CI 执行文案完整性检查、本地化生成、analyze、test 和 Windows 构建。

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

## 窗口退出回归

`test/app/application/` 覆盖退出顺序、重复请求、播放器 / 主窗口清理失败与超时，以及排队周期保存和最终快照在 SQLite 关闭重开后的持久化。`player_window_coordinator_test.dart` 覆盖退出期间的原生创建竞争、拒绝排队启动、旧窗口退役和过期关闭通知；`player_window_close_coordinator_test.dart` 验证保存 / 释放结果确认及失败后继续清理。播放会话与设置测试补充切集期间退出、等待已接受保存并拒绝新保存。

手工验收在 macOS / Windows 分别执行：

1. 无播放器时关闭主窗口，确认窗口消失且进程结束；macOS 另测菜单退出、Cmd+Q 与 Dock 退出。
2. 播放后单独关闭播放器，确认最后进度保存，主窗口继续可操作并可再次启动播放器。
3. 播放过程中关闭主窗口，确认最后进度保存、全部窗口关闭，进程结束；重新启动检查续播位置。
4. 在 mini、置顶、全屏状态分别重复第 2、3 项。
5. 连续点击关闭、启动 / 切集期间退出，确认没有残留窗口或重复播放。
6. 模拟子窗口或写入无响应，确认退出有界；查看失败阶段日志，不把超时退出当作最后快照成功保存。

构建和单元测试不替代视频渲染、原生窗口及进程退出的手工验收。

2026-10-11 验证记录：`flutter analyze` 无问题，全部 186 项测试通过，macOS Debug 构建成功。macOS 使用临时检查入口、隔离 SQLite 和模拟播放资源验证了原生双窗口 / RPC：子窗口独立关闭并重新创建、带子窗口关闭主窗口、子窗口聚焦时 Cmd+Q；记录确认最终进度写入后才释放资源、关闭子数据库，随后关闭主数据库并结束进程。临时入口不随项目交付。真实视频 mini / 全屏、Windows 原生运行时及无响应注入仍待验收。

## 播放引擎门面回归

`playback_engine_boundary_test.dart` 注入 `FakePlaybackEngine`，验证打开媒体时的目标 / 认证头和类型明确的设置、轨道事件及音频元数据、外挂字幕加载与再次选择、字幕关闭 / 样式覆盖、控制栏播放与 seek，以及退出时暂停 → 最终保存 → 释放的顺序与重复释放。原有外挂字幕路径和日志脱敏测试改为使用项目类型，不依赖 media_kit。

2026-10-12：全部 190 项测试通过，`flutter analyze` 无问题，macOS Debug 构建成功。假引擎回归验证门面与业务 / UI 的交互，不替代后端参数效果、真实视频渲染、硬解和 Windows 运行时验收；能力基线与维护风险见 [ADR 0002](../decisions/0002-playback-engine.md)。

## 本地化回归

干净检出和修改 ARB 后，先执行 `fvm flutter pub get`、`fvm dart run tool/check_l10n.dart`、`fvm flutter gen-l10n`，再执行 analyze / test / build。生成目录 `lib/l10n/generated/` 被忽略；模板缺译、未知 key 或缺少占位符会使检查失败。

`test/l10n/` 验证系统语言回退、三种偏好、持久化 / 重启、快速切换、过期消息拒收、退出收尾、语言选择控件、英文 Material 文案、日期 / 数字格式与单复数、结构化错误提示、语言切换不重新挂载会话。播放器窗口协调器测试补充就绪 / 复用的语言校准和原生创建期间切换。既有 Widget 测试显式配置中文及委托，避免依赖执行机器的系统语言。

2026-10-12 本轮验证：275 条中英文文案完整性检查通过，删除生成目录后重新生成成功；`flutter analyze` 无问题，全部 201 项测试通过，macOS Debug 构建成功。生成代码未纳入 Git。

同日收尾修复：占位符改为语义名称，计数使用整数与 locale 数字格式，目录连接 / 删除 / 扫描提示补齐英文复数规则，扫描结果的连接标点交给 ARB。语言偏好区分当前选择与已成功保存的值，保存失败后可重试同一选择，且不会重复广播。回归新增保存失败重试和计数边界测试；277 条文案检查通过，静态检查无问题，全部 203 项测试通过。

手工验收按 [ADR 0004](../decisions/0004-i18n-l10n.md) 的回归基线执行；特别检查真实播放不中断、进度不重置、已有弹层与长英文布局、系统语言变化及 macOS / Windows 原生交互。当前 UI 自动验收工具无法绑定改名后的 macOS 应用，完整页面与原生双窗口验收仍待完成。
