# 代码组织与新增功能

本指南约束整个仓库的新增与修改。统一方向见 [ADR 0007](../decisions/0007-unified-module-boundaries.md)，当前机制和资源所有权见 [架构总览](../architecture/overview.md)，验证命令见 [测试指南](testing.md)。

## 可维护性四原则

1. **一个功能有明确入口。** 从查询、扫描、来源保存或播放会话的入口扩展，不并列创建另一套实现。
2. **同一流程代码靠近，职责仍能辨认。** 先按功能和维护流程定位，再用统一职责目录区分 UI、状态与用例、模型与规则、外部适配。
3. **拆分必须有独立价值。** 跨边界的模型与 Mapper 分开；有独立消费者的模型独立成文件。私有实现细节及同一契约的进度、事件等伴随类型可以就近放置，不为类型数量机械建层。
4. **名字对应实际职责。** 文件、公开主类型和参数含义一致。VO 不是状态 ViewModel，Provider 不是数据库服务，Repository 实现不混在业务契约中。

评审使用具体维护任务检验结构：修改标题匹配、来源认证、收藏查询或字幕样式时，应能找到明确入口和有限的相关文件。减少行数或通过测试不能单独证明架构易维护。

## 目录骨架

职责目录统一为 `ui / application / domain / data`，按实际内容创建。

```text
lib/
├── app/
│   ├── bootstrap/       # 选择实现、显式依赖组装与窗口工厂
│   ├── application/     # 应用退出与跨资源生命周期
│   ├── routing/         # 导航路径与路由组装
│   └── ui/              # 应用外壳与跨功能界面组合
├── features/
│   └── <功能或流程>/
│       ├── ui/          # 页面、弹窗、组件与具体界面交互
│       ├── application/ # Provider、用例编排、能力契约与业务输入映射
│       ├── domain/      # 业务模型、输入语义及纯规则
│       └── data/        # SQL、网络、协议和播放后端的具体实现
├── core/
│   ├── application/     # 跨功能的纯应用辅助能力
│   ├── domain/          # 共享模型、规则及存储 / 播放能力契约
│   ├── data/            # 共享数据库、协议与 TMDB 基础设施
│   ├── platform/        # 所属视图的窗口契约与原生适配
│   └── ui/              # 共享组件、主题及图片渲染资源适配
└── l10n/
    ├── application/     # 语言状态与持久化契约
    ├── domain/          # 语言偏好模型
    ├── data/            # 语言偏好存储
    └── generated/       # ARB 生成的本地化实现
```

媒体库的 `browser / catalog / detail / sources / sync / metadata` 是维护流程，每个流程沿用上面的职责目录。公共媒体库入口位于 `library/application`，共享规则位于 `library/domain`，共享媒体库 UI 位于 `library/ui`。具体路径见 [媒体库维护地图](../../lib/features/library/README.md)；播放见 [播放维护地图](../../lib/features/playback/README.md)。测试按被测代码职责镜像组织；生成的历史 schema 夹具位于 `test/generated`。

## 依赖方向

- `ui → application → domain`：界面依赖状态、用例或播放 / 窗口契约，领域不反向依赖 UI、用例或数据 SDK。
- `data → application / domain`：数据适配实现调用方所需的契约，读取 DO、外部响应并通过 Mapper 返回业务对象或查询 VO。
- `app/bootstrap` 和启动入口选择具体实现并注入。Provider 不导入 `data`，不直接访问 SQLite、SharedPreferences、HTTP 或第三方协议客户端，也不在缺少参数时偷偷创建后端。
- `core` 不依赖 `features / app`。跨功能协作保持单向；设置页需要展示媒体源面板时，由应用外壳注入组件，不让设置和媒体库形成循环。
- 功能 UI 不直接读取数据库、凭据或具体缓存实现。媒体图片经 `core/ui/images/MediaNetworkImage` 适配渲染资源；这是共享资源边界，缓存和代理配置仍留在数据适配中。
- 数据访问不能依赖 UI。模型不能包含 drift 行映射、JSON 编解码或网络 SDK。业务校验、规范化和身份规则可以保留在领域模型或领域规则中。

## data 具体包含什么

`data` 适配数据库、网络、协议、偏好存储和播放引擎等外部能力。

| 职责 | 当前类 | 是否执行 I/O |
| --- | --- | --- |
| SQLite 定义、连接及持久化入口 | `AppDatabase` | 是 |
| 实现特定流程的数据契约 | `LibraryCatalogRepositoryImpl`、`AppSettingsRepositoryImpl` | 是 |
| 外部 API 端点及 HTTP 传输 | `TmdbApi`、`TmdbHttpClient` | 是 |
| 协议连接及后端实现 | `SmbStorageAdapter`、`SmbStorageConnection`、`MediaKitPlaybackEngine` | 是 |
| 数据边界转换 | `MediaFileMapper`、`TmdbMetadataMapper` | 否 |
| 边界参数解析 | `HttpProxyParser` | 否 |

`Service` 用于说明业务流程编排，例如 `LibrarySyncService`、`StorageSourcesService`，放在 application。平台契约 `WindowService` 表示原生窗口操作能力，保留平台约定；不因为名字中有 Service 就把它当成业务层。先看实际职责，再选择名称和目录。

## 模型术语与数据访问层

| 类型 | 职责与当前实例 | 转换位置 |
| --- | --- | --- |
| DO | 数据库记录：`MovieDO / TVShowDO / SeasonDO / EpisodeDO / MediaFileDO / StorageSourceDO`，由 drift 生成 | `core/data/database/mappers` 中的专属 Mapper |
| 业务模型 | `Movie / MediaFile / StorageSource / PlaybackQueue` 等业务数据与规则，不作为数据库行类型 | 只接收或返回业务类型；不依赖存储结构 |
| VO | **View Object，展示对象**：`MediaCardVO / MediaDetailVO`，不是 DDD 的 Value Object | `MediaCardMapper / MediaDetailMapper`；VO 本身只保存展示字段 |
| DTO / 外部响应 | 外部边界的数据形态；当前 TMDB 原始 JSON 留在 data 内 | `TmdbMetadataMapper` 显式从 JSON 转换，不让 JSON 进入 Provider 或业务模型 |
| 用例输入、结果与进度 | `ScrapeCandidate / ScrapeResult / ScrapeProgress / PlayerWindowRequest` 等，名称直接说明用途 | 有实际字段转换时由 Mapper 创建；只读业务候选可引用原始不可变模型，同一契约的伴随数据就近放置 |

数据访问代码位于 `data`。Repository 是能力契约，当前每个仓库只有一个生产实现，统一使用 `接口名Impl`，文件为 `*_repository_impl.dart`。

数据库使用独立 DO，保存数据库字段、枚举字符串和 JSON 文本；Mapper 在边界转换为业务枚举及列表。数据库关系数据分别加载后组装，不能为每个卡片新增一条 SQL。VO 字段可以携带操作上下文的业务对象，但不能持有 Widget、连接、订阅或请求。

## 控制维护成本

- 同一业务事实只保留一份数据来源。例如 `ScrapeCandidate` 引用 `MediaFile` 并派生读取字段，不同时保存两份标题和匹配 ID；纯复制且没有转换规则的 Mapper 可以合并。DO、业务模型、VO 的外部边界转换仍独立保留。
- 一个真实边界保留一份契约。Repository 隔离功能需要的数据能力，`AppDatabase` 管理数据库连接和公共读写。
- 接口以生产调用为保留依据，测试通过正式入口验证行为。
- 只有一个创建规则的简单工厂并入所属业务模型，例如 `ScrapeSearchPlan.forCandidate`；业务校验与创建规则可以放在模型中，外部格式转换仍由 Mapper 负责。
- 文件变长不自动意味着拆分。播放器菜单、文件名解析和同一界面的小组件可以留在同一流程内；只有能独立理解、复用或隔离资源所有权时才拆出文件。
- 不为统一后缀引入 Facade、Manager、Store、Handler 等新概念。已有名称先检查职责；优先减少转发和重复状态，再决定是否更名。
- 异步入口明确停止与销毁行为。接受的保存继续排空；销毁后不通知界面、不应用迟到配置；迟到读取不覆盖用户已经修改的偏好。保存插件返回 false 也属于失败。

## 命名约定

Repository 接口保留能力名称，实现采用同名主干加 `Impl`；存储技术在实现文件的中文说明和代码中明确。只有实际出现多个生产实现时，才使用技术前缀区分，不提前为可能的后端增加名称。测试替身按 Fake / Stub 的实际用途命名。

文件名与主要公开类型对应，使用 `snake_case`；后缀表达职责，不按继承关系机械命名。

| 名称 | 使用场景 | 示例 |
| --- | --- | --- |
| `Provider` | 可订阅界面状态与操作入口，统一在 application | `MediaLibraryProvider`、`AppSettingsProvider` |
| `Controller` | 界面交互或会话状态机；按职责放 ui 或 application | `PlayerSubtitleController`、`PlaybackSessionController` |
| `Service / Coordinator` | 具体用例编排、多个参与者的顺序协调 | `LibrarySyncService`、`PlayerWindowCoordinator` |
| `Repository / Source / Engine` | 调用方所需能力契约 | `LibraryCatalogRepository`、`TrendingMediaSource`、`PlaybackEngine` |
| `RepositoryImpl` | 与仓库接口同名主干的唯一生产实现，统一放 data | `LibraryCatalogRepositoryImpl`、`ThemePreferencesRepositoryImpl` |
| 后端前缀 | 协议、外部数据源或播放引擎适配 | `TmdbTrendingMediaSource`、`MediaKitPlaybackEngine` |
| `Api / HttpClient` | 外部服务端点 / 底层 HTTP 传输 | `TmdbApi / TmdbHttpClient` |
| `Mapper` | 边界转换，不查询、不保存、不通知界面 | `MediaFileMapper.toDomain / toDO`、`MediaDetailMapper.toVO`、`TmdbMetadataMapper.movieFromJson` |
| `Page / Panel / Dialog` | 完整页面、可嵌入面板、弹窗 | `FileBrowserPage`、`StorageSourcesPanel`、`showSmbSourceDialog` |
| 具体业务名称 | 已经表达用途的模型与规则 | `ParsedMediaFilename`、`ScrapeSearchAttempt`、`PlaybackResumePolicy` |

查询结果的界面组件带 `View`，例如 `LibraryQueryView`；可关闭的扫描资源带 `Session`，例如 `LibrarySourceScanSession`；普通数据对象不使用看起来像转换器或 Widget 的名称。只供 Selector 比较和界面重建使用的私有数据命名为 `...Snapshot`，与 Flutter 的 `State<Widget>` 区分。

Provider 包只是一种注入机制，不要求每个服务都套一层 Provider。简单动作不增加仅转发参数的 Service；接口隔离真实的持久化、协议、网络或播放后端边界。共享 UI 使用 `App` 前缀；功能专属组件使用实际业务名称。修正类型名时同步参数名和使用点，不保留旧名别名或转发文件。

## 中文文件说明与资源所有权

手写 Dart 文件开头用中文说明实际职责和协作边界，不能只重复文件名。涉及连接、引擎、订阅、浮层、计时器和任务时，说明谁创建、谁持有、何时释放。非直观的失败与竞争处理用中文解释原因，保留必要的代码标识。

数据库与设置等共享实例由应用创建；窗口能力按视图创建；引擎与播放目标归会话持有。转换器和纯规则不接管外部资源。已有播放关闭顺序见 [播放架构](../architecture/playback.md)，不得因重构改变收尾顺序。

生成的本地化、drift 数据库与 schema 测试夹具由生成工具维护，不手工添加注释。机器识别的指令、许可证和外部地址保持原样。

## 新增功能与评审

接口文档必须让调用方不读实现也能正确使用：说明 ID 身份、数值单位、空值与布尔结果含义、排序、失败方式及写入副作用。说明依据当前行为，不承诺实现没有提供的校验或事务；实现专属的 SQL、存储键和插件细节留在 data。组装处创建具体实现，对外字段优先声明为调用方所需的接口类型。

先确定入口和数据流，再沿统一层次扩展。例如手动修正匹配：界面弹窗放 `metadata/ui`，操作编排和外部能力契约放 `metadata/application`，匹配输入与规则放 `metadata/domain`，TMDB / 数据库实现及边界 Mapper 放 `metadata/data`；实例由应用组装。此示例是落位规则，不代表手动匹配已经实现。

完成后运行格式检查、架构检查、静态检查及受影响测试。架构检查阻止旧目录、Provider 直连后端、领域序列化、模型兼作数据库行和跨功能循环重新出现，并在 CI 执行。功能与机制变化同步对应文档，技术方向变化更新 ADR，验证证据集中更新测试指南。

### 表单布局约定

- 输入字段可用固定标签列；开关、按钮保留自身宽度，文字使用剩余空间。开关行复用 `AppFormSwitchItem`。
- 说明和错误允许换行，行高随内容增长。需占用整行时用 `AppFormItem.subtitleBelowControl`，不省略操作后果或必要路径。
- 占位提示提供格式或短示例，不重复标签，不作为实际默认值。
- 修改共享组件时检查窄弹窗、中英文和放大字号。布局参考 [Ant Design Form](https://ant.design/components/form/) 与 [MUI Switch](https://mui.com/material-ui/react-switch/)。

### 媒体源表单约定

| 项目 | 规则 |
| --- | --- |
| 连接测试 | 标题下显示结果，右侧按钮按内容宽度居中；成功仅显示“连接成功”，失败原因可换行，不展示目录项数 |
| 本地路径 | 在整行下方显示，允许换行 |
| WebDAV 主机 | 占位提示 IP / 域名 |
| WebDAV 端口 | 必填，测试和保存均校验整数 1–65535；提示“如：5244”。5244 是 OpenList 等服务的示例，不是通用默认端口；编辑时显示 URL 实际端口，含 80 / 443 |
| WebDAV 路径 | 新建时留空，显示 `/dav` 示例；留空提交表示根路径 `/` |

### 开发检查

- 开始编码前阅读架构总览、本指南及相关功能文档 / ADR，找到已有调用入口与可复用能力。
- 确定目录归属、类型职责、依赖来源与资源所有者后再实现；遵守现有命名，不因新增功能整体改名。
- 修复或替换实现时移除废弃路径，不增加旧名别名、重复入口或无调用方的兼容转发。确有兼容需求时，在文档中明确对象、理由与移除条件。
- 测试围绕业务行为和边界组织，按 [测试指南](testing.md) 选择单元、Widget 或原生集成验证；不为低影响的目录调整添加只复述实现的测试。
- 完成后检查是否出现页面访问基础设施、模块循环、隐藏依赖创建、重复实现或资源未释放；执行受影响的检查，并同步架构文档。技术方向变化更新 ADR，交付阶段变化更新 `status.md`。

本骨架的变更应有明确的职责、依赖或实际维护路径问题作为依据。外部 Flutter 项目的目录可用于研究取舍，不作为改变本项目规则的直接理由。
