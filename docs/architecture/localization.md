# 本地化

本文说明当前语言状态、文案生成与展示边界。采用官方 gen-l10n 的理由与语言范围见 [ADR 0004](../decisions/0004-i18n-l10n.md)，完成度见 [实施状态](../status.md)。

## 代码入口

| 入口 | 职责 |
| --- | --- |
| [app_en.arb](../../lib/l10n/app_en.arb)、[app_zh.arb](../../lib/l10n/app_zh.arb) | 英文模板与简体中文译文 |
| [l10n.yaml](../../l10n.yaml) | 生成目录、模板与输出文件配置 |
| [AppLocaleProvider](../../lib/l10n/application/app_locale_provider.dart) | 语言选择、持久化、回退与共享通知 |
| [l10n.dart](../../lib/l10n/l10n.dart) | 展示层获取当前语言与业务错误文案 |
| [main.dart](../../lib/main.dart)、[PlayerWindowApp](../../lib/features/playback/ui/player_window_app.dart) | 两个 MaterialApp 的 locale、委托与支持语言接线 |
| [check_l10n.dart](../../tool/check_l10n.dart) | 资源 key、译文与占位符完整性检查 |

## 语言状态与回退

`AppLanguage` 保存 `system / zh / en`，SharedPreferences 键为 `app_language`。缺失或非法偏好回到 `system`。

- 跟随系统时 `locale` 为 null，按系统语言列表依次匹配 `zh / en`，没有匹配项时回退英文。
- 中文 locale 使用简体中文资源，不另设繁体译文。
- 主视图与播放器共享一个 `AppLocaleProvider`，通知直接重建各自的 MaterialApp。
- 切换语言不替换播放会话，不重开媒体或重置主题、扫描、字幕选择与播放进度。

偏好写入按接受顺序串行执行。当前选择与成功保存的值分开维护，保存失败后可以重试相同选择；退出时拒绝新变更并排空已接受写入。播放器复用 / 替换时继续使用该共享实例。

## 文案与格式化

业务文案通过 `context.l10n` 在展示时解析。后台任务返回 `AppFailure`、`LibraryActivity` 等类型，避免把 BuildContext、已翻译字符串或原始网络异常传入纯 Dart 服务；挂起任务完成后使用展示时的语言。

季集、数量和组合提示使用 ARB 参数及 ICU 复数；日期 / 数字通过 intl 显式指定当前 locale。[FileBrowserEntryDisplay](../../lib/features/library/browser/ui/file_browser_entry_display.dart) 在展示层格式化，不向领域模型注入 Flutter 依赖。

标准剪切 / 复制 / 粘贴菜单使用 Flutter 本地化资源，自定义操作走 ARB，菜单样式、操作与启用条件由项目组件控制。日志、文件解析规则和字幕语言匹配中的中文不是界面翻译资源。

界面语言不改变媒体文件名、用户输入、TMDB 元数据语言或字幕优先级。系统原生文件选择器与 macOS 菜单受操作系统 / 平台资源控制。

## 生成与检查

配置以 `l10n.yaml` 和 `pubspec.yaml` 为准：SDK 的 flutter_localizations、`flutter.generate: true`、英文模板、`lib/l10n/generated/` 输出、`nullable-getter: false`。

ARB、配置与调用代码入库，生成目录不入库。首次检出或修改 ARB 后，先完整性检查与生成，再执行静态检查、测试及构建；完整命令统一见 [测试指南](../guides/testing.md#推荐运行顺序)。模板回退可能掩盖缺译，因此生成成功不能代替资源检查。
