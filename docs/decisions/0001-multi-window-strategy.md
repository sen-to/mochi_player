# 0001 多窗口策略：保留多窗口，把「引擎」从架构中摘除

- **Status**: Accepted
- **Date**: 2026-10-05
- **Related**: [0002 播放引擎](0002-playback-engine.md)、[0005 SMB 播放路径](0005-smb-playback-path.md)

## Context（背景与约束）

产品需求（必须保留）：

- 播放器可开在**独立窗口**，可收成 mini 播放器并置顶；
- 关闭媒体库主窗口后播放器继续播放，进程保持存活，直到播放器窗口也关闭。

当前实现：`desktop_multi_window` 0.3.1，**一个窗口一个 Flutter 引擎**。由此产生三类已知代价：

1. **Windows 主窗口冻结**。打开播放器窗口后主窗口可能出现鼠标/键盘无响应，且关闭播放器窗口也不恢复；已作为已知限制写入用户文档（[README.md:218](../../README.md#L218)），并在 runner 中用 `UIThreadPolicy::RunOnSeparateThread` 规避（[flutter_window.cpp:26](../../windows/runner/flutter_window.cpp#L26)）。
2. **两个引擎各自打开同一数据库**。主窗口在 [main.dart:33](../../lib/main.dart#L33) 初始化，播放器子引擎在 [player_window_app.dart:379](../../lib/features/playback/presentation/player_window_app.dart#L379) 再次初始化，且子引擎会写入播放进度。
3. **窗口生命周期逻辑与业务代码纠缠**：跨引擎只能传引用而不传凭据、启动串行化、旧窗口退役轮询、等待就绪等逻辑目前与播放器启动流程写在一起（[player_window_app.dart](../../lib/features/playback/presentation/player_window_app.dart)）。

官方方向：Flutter 已提出 Desktop Windowing API（单引擎多视图，[flutter.dev 公告](https://flutter.dev/blog/desktop-windowing-apis)），但截至撰写时仍处于「需要显式启用、尚未成为桌面端默认能力」的阶段，社区仍在讨论其落地节奏。因此现在切换不可行，但可以提前准备好退路。

## Decision（决策）

**多窗口是产品目标，长期保持；「一个窗口一个引擎」只是可替换的实现细节。**

必须遵守的规则：

1. 窗口的创建、激活、关闭、尺寸与置顶，**必须**经由统一的窗口服务门面（约定的接口名 `WindowService`，配套 `WindowHandle`），业务代码不得直接调用 `desktop_multi_window` 的 API。
2. **媒体库数据库只允许主窗口写入**。播放器窗口不得直接写库；播放进度通过主窗口与播放器窗口之间已有的通道回传，由主窗口落库。
3. 跨窗口契约携带 `sourceId + path`；临时文件浏览项可附带文件名、大小等最小回退元数据，让未入库文件也能播放。不得把已解析 URL、请求头、凭据或活动中的 provider 实例放进窗口参数。
4. 播放器窗口的 UI 与窗口模式（独立窗口 / mini / 全屏 / 置顶）**不得**依赖引擎数量假设，以便在单引擎多视图下复用。

迁移目标：官方 Desktop Windowing API 达到可用门槛后，先迁移播放器窗口，媒体库主窗口最后迁移。

## Consequences（后果）

- **正面**
  - Windows 冻结风险被隔离在一个接口后面，替换实现即可消除，不需要重写业务逻辑。
  - 「数据库单写者」独立于多窗口决策，立即消除双引擎写库的不确定性（与 [0003](0003-persistence-migration.md) 的迁移目标一致）。
  - 窗口契约稳定后，未来无论走官方 API 还是原生子窗口，业务层都不用改。
- **负面**
  - 短期内 Windows 冻结缺陷依然存在，用户文档中的已知限制要继续保留。
  - 多一次间接层（`WindowService`），窗口相关调试要多跳一层。
  - 进度改为主窗口落库后，播放器窗口关闭瞬间的进度需要一次强制 flush，否则会丢最后一次快照（现有实现已有 flush 机制，需保证迁移后仍走同一路径）。
- **跟进**
  - 抽取 `WindowService` 并让 `player_window_app.dart` 只依赖它；
  - 播放进度改为经通道回传、主窗口落库；
  - 在用户文档中把「Windows 主窗口可能无响应」标注为「计划在切换窗口方案后消除」。

## Alternatives（备选与否决理由）

| 备选 | 否决理由 | 什么条件下变成首选 |
| --- | --- | --- |
| **取消独立窗口**，播放器做成应用内全屏页面 | 成本最低，可一次性消除多引擎的全部缺陷；但放弃了「小窗置顶边看边干别的」这一产品价值 | 若官方方案长期不可用、且用户对独立窗口需求很弱，可作为产品取舍重新评估 |
| **原生子窗口 + 播放器渲染到原生窗口**（`mpv_render_context` / `--wid`） | 需要为 macOS/Windows 各写一套窗口与渲染代码，成本最高 | 官方 API 在两个 Flutter 大版本内仍不可用于双平台独立窗口，或 Windows 冻结问题影响扩大到主流程时，作为 Plan B |
| **继续深度绑定 `desktop_multi_window`** | 该包维护强度低、多引擎是缺陷根源，越深绑定迁移越贵 | 不适用 |

## Revisit trigger（重估触发条件）

满足任一条即重新评估本决策：

1. 官方 Desktop Windowing API 进入 stable，且支持 macOS 与 Windows 上的**次级独立窗口**（具备独立尺寸、置顶、关闭事件）；
2. Windows 冻结问题的影响面扩大（例如启动播放器即复现，或影响进度写入正确性）；
3. `desktop_multi_window` 停止维护，或与目标 Flutter 版本不再兼容。
