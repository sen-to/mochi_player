# 2026 年 10 月验证历史

本文保留阶段验证与关键故障，记录按阶段合并，整理日期不作为测试执行日期。当前完成度见 [实施状态](../status.md)，最新基线、运行命令与手工清单见 [测试指南](../guides/testing.md)。

## 阶段验证

以下为当时的原生验证记录。未注明应用提交的记录无法精确对应某次检出。选型原型依据见 [ADR 0001](../decisions/0001-multi-window-strategy.md#选型验证依据)。

| 日期 / 阶段 | 记录结果 | 范围与限制 |
| --- | --- | --- |
| 10-13，官方多视图迁移 | 198 项测试、277 条文案检查、macOS Debug / Release 构建通过；隔离播放冒烟完成 | 双视图共享语言 / 数据库、置顶、mini 尺寸、替换、关闭重开与最终进度；RGB AVI 不代表真实编码 / HDR，frame-time 诊断仍有出现；全屏修正见下文 |
| 10-14，依赖升级与职责分离 | 升级阶段 209 项、职责分离后 227 项测试通过；277 条文案检查及生成通过；macOS Debug 构建与播放冒烟通过 | 临时连接释放、退出排空、迟到连接、共享依赖与查询刷新；`WINDOWING SMOKE COMPLETE` 覆盖新工厂 / 控制器与 SQLite 关闭重开。该阶段没有新的完整 Release / 签名验收 |
| 10-14，文件对话框与标题栏 | 人工验收反馈确认文件对话框通过；标题栏重命名的 3 项通道测试与 Swift 语法检查通过 | 人工确认未逐项注明平台 / 边界；通道测试不证明原生视觉效果 |
| 10-17–18，Windows 启动与尺寸 | 228 项测试、静态检查、Debug 启动、Release 构建与窗口冒烟通过 | 输出 `WINDOWING SMOKE COMPLETE`、`WINDOW CONSTRAINTS SMOKE COMPLETE`；验证纹理、双视图、mini / 全屏、换片、关闭重开与最终进度。包含语义树禁用规避；不代替鼠标缩放、DPI、输入或长期播放验收 |
| 10-23，SMB 回源与快速 seek | 提交 `d23458b`：最终 260 项测试、275 条文案检查、格式与静态检查通过；macOS Release 两类播放冒烟通过 | 输出 `SMB HTTP RAPID SEEK PASS`、`SMB HTTP PLAYBACK SMOKE COMPLETE` 与 `WINDOWING SMOKE COMPLETE`；HTTP 使用读取替身，未连接 NAS。问题报告所用的 NAS / MP4、Windows SMB 与高码率仍未验收 |

静态检查在官方多视图迁移后保留固定 SDK 的旧 Material / Cupertino 导入弃用 info；记录中的“通过”不表示没有这些提示。对应的 [官方 UI 包迁移说明](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui) 保留为后续升级依据。

## 关键故障与处理

### Windows CI：测试宿主初始化与 C++ 宏冲突

| 证据 | 原因与处理 | 结果边界 |
| --- | --- | --- |
| [首次 master CI](https://github.com/sen-to/mochi_player/actions/runs/38505530613/job/115662050561) | 26 个测试文件因缺少 `InternalFlutterWindows_WindowManager_Initialize` 加载失败；在创建 binding 前关闭普通测试进程的实验窗口能力，正式应用继续启用 | 当次静态检查通过、原生构建未执行；测试隔离不代表产品关闭多视图 |
| [第二次 CI](https://github.com/sen-to/mochi_player/actions/runs/38509922678/job/115675829212) | 209 项测试通过，原生构建因 Win32 `small` 宏冲突失败；变量改为 `int32_value`，本地宏复现检查通过 | 随后收到 CI 成功的人工反馈，记录未附成功运行链接；仅确认构建，不确认原生交互 |

测试隔离机制见 [测试宿主](../guides/testing.md#测试宿主与真实窗口)，SDK 升级后需复查。

### Windows：两类不同的原生崩溃

| 故障 | 定位与处理 | 验证及代价 |
| --- | --- | --- |
| 插件注册时退出 | `media_kit_video 2.0.1` 解引用不存在的隐式视图，模块为 `media_kit_video_plugin.dll`、异常 `0xc0000005`；替换注册源文件，改用插件自己的 message-only 窗口 | Debug 启动与 Release 纹理 / 播放冒烟通过；升级插件后需复查并移除补丁，详见 [Windows 指南](../guides/build-windows.md#media_kit_video-的无隐式视图兼容补丁) |
| 缩放窗口时 AXTree 崩溃 | `flutter_windows.dll + 0x3cf46`，异常 `0xc0000005` / `0xc000041d`；固定 SDK 的 PDB 定位到 `AccessibilityBridge::CreateRemoveReparentedNodesUpdate + 186`。上游有 [报告 #175041](https://github.com/flutter/flutter/issues/175041) 与 [空父节点修复 #190903](https://github.com/flutter/flutter/pull/190903)；项目暂时禁用 Windows 语义树 | 正式启动及 Release 冒烟未再输出 AXTree 错误；Windows 读屏不可用，未证明 SDK 根因修复或人工缩放通过，移除条件见 [平台指南](../guides/build-windows.md#临时关闭-windows-无障碍语义树) |

**失效结论**：AppSlider 局部 Overlay 曾在隔离测试中消除 AXTree 错误，但后续人工反馈表明正式应用仍有问题；该方案及隔离缩放入口已撤回，不能作为修复证据。

### 窗口最小尺寸与 macOS 全屏

- **Windows 最小尺寸**：固定 SDK 创建窗口时未保存宿主约束，适配层创建后重新设置。10-18 原生冒烟通过 `WM_GETMINMAXINFO` 检查主窗口 900×600、播放器 720×405、mini 420×260 及恢复、视图隔离与重开；不替代鼠标拖动 / DPI 验收。
- **macOS 最小尺寸**：问题反馈指出窗口可无限缩小，原生桥在标题栏配置后重设 `contentMinSize`。当时没有执行 Mac 专项；后来的播放冒烟不能替代该项验收，当前证据见 [验证基线](../guides/testing.md#验证基线)。
- **macOS 全屏**：固定等待一秒曾误判动画完成，状态位更新后立即退出可能丢失请求。改为等待 AppKit 完成通知，覆盖重复点击、转换中关闭与失败重试；修正后的播放集成检查完成退出及 SQLite 重开。原先仅凭延时的“全屏通过”结论失效。
- **退出超时**：10-14 将资源释放 / 窗口恢复等待扩展到 12 秒，覆盖全屏动画；无响应仍有界结束。具体关闭顺序与各阶段上限统一见 [播放生命周期](../architecture/playback.md#生命周期与退出)，超时退出不保证最后快照保存。

### SMB：快速 seek 被旧请求阻塞

10-23 回归复现：源读取阻塞时连续中断 8 个 Range 请求，最新请求收到 503 而非 206。`HttpResponse.done` 不保证在下一次写入前发现断开，只等待它回收名额不可靠。

修复为最多保留 4 个活动传输，新请求替换最旧传输；SMB 读取出队前检查取消，超时任务也取消。回归要求最新范围返回正确字节、旧任务不阻塞新请求，并覆盖新媒体打开失败时释放旧目标、迟到结果释放与重复关闭。协议细节见 [SMB 回源](../architecture/playback.md#smb-http-回源)。

macOS Release 使用 40 秒 RGB AVI、每块 30ms 读取延迟，连续三轮快速 seek 后继续跳转，两个 SMB 成功标记均输出。该结果验证真实播放器与 HTTP 服务，**未证明问题报告所用的真实 NAS / MP4 已修复**；所附 frame-time clamping 日志也不能单独证明 SMB 故障原因。

### macOS：原生依赖警告

Podfile 钩子修正插件宏列表后，`pod install --no-repo-update` 与 Debug 构建成功，日志不再出现宏重定义；依赖版本及 Podspec 校验值未变，仅 Podfile 校验值更新。具体执行日未单独记录。

SPM 提示仍存在；增量构建未输出 `objc_ownership` 警告不能证明上游生成接口已修复。警告来源与补丁移除条件见 [macOS 指南](../guides/build-macos.md#原生依赖警告)。

## 工具链依据

2026-10-13 锁定 SDK `5ba8961b517919e97cd58e404b75dcdcf313017a`，FVM 显示 Flutter `3.49.0-1.0.pre-447` / `master`，使用预编译引擎。项目锁定值以 [`.fvmrc`](../../.fvmrc) 为准，选型依据见 [ADR 0001](../decisions/0001-multi-window-strategy.md#选型验证依据)。
