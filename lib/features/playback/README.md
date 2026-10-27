# 播放维护地图

从要修改的行为找到入口。播放请求、会话、展示交互分别有明确的所有者；不需要从所有 Controller 开始阅读。

| 要改什么 | 从这里开始 | 边界 |
| --- | --- | --- |
| 点击播放、选择剧集与队列 | [presentation/playback_launcher.dart](presentation/playback_launcher.dart) | 创建播放请求；复用媒体库查询和共享剧集目标规则 |
| 播放器窗口打开 / 复用 | [application/player_window_coordinator.dart](application/player_window_coordinator.dart) | 串行处理窗口请求；实际窗口创建在 `app/bootstrap/player_window_factory.dart` |
| 打开 / 换片、播放目标与引擎释放 | [application/playback_session_controller.dart](application/playback_session_controller.dart) | 会话持有引擎和目标资源；准备失败、打开失败、换片和关闭都从这里收尾 |
| 缓冲提示、续播提示、音轨与音量交互 | [presentation/controllers/player_playback_controller.dart](presentation/controllers/player_playback_controller.dart) | 将界面操作交给会话或借用的引擎；不负责协议连接与数据库细节 |
| 自动 / 手动选字幕、外挂字幕、字幕覆盖 | [presentation/controllers/player_subtitle_controller.dart](presentation/controllers/player_subtitle_controller.dart) | `PlayerPlaybackController.subtitles` 为入口；文件转轨道的伴随工具在同文件；不拥有引擎 |
| 快捷键、视频及字幕布局 | [presentation/pages/player_page.dart](presentation/pages/player_page.dart) | 接线、布局和文件选择；字幕业务进入 `subtitles` |
| 控制栏、选轨菜单 | [presentation/widgets/player_controls.dart](presentation/widgets/player_controls.dart) | 通过状态与回调工作，不创建会话或解析播放地址 |
| mini / 全屏与窗口恢复 | [presentation/controllers/player_window_mode_controller.dart](presentation/controllers/player_window_mode_controller.dart) | 使用所属视图的 WindowService；不转移播放会话所有权 |
| 最终进度写入、串行保存 | [application/playback_progress_writer.dart](application/playback_progress_writer.dart) | 会话决定何时写入；数据库适配在 `infrastructure/database_playback_media_repository.dart` |
| media_kit / mpv 参数 | [infrastructure/media_kit_playback_engine.dart](infrastructure/media_kit_playback_engine.dart) | 后端细节限于此实现，调用方使用 `application/playback_engine.dart` |

## 状态与关闭

- `PlayerPlaybackController` 创建并持有字幕控制器，页面直接使用 `subtitles` 的状态和操作，不增加同名转发方法。
- 字幕控制器持有自己的轨道 / 文本订阅和媒体内字幕状态。换片前使旧异步操作失效，切换成功时重置；样式偏好继续保留。
- 关闭时拒绝新交互，取消播放和字幕订阅，再调用会话关闭释放引擎及播放目标。字幕控制器不打开、停止或释放引擎。
- 共享媒体类型、观看进度规则和剧集目标选择由媒体库与播放共同使用，仍留在 `core`；功能专属交互留在播放功能内。

测试与实现镜像放在 `test/features/playback/`；字幕行为和异步竞争在 `presentation/controllers/player_subtitle_controller_test.dart`，引擎 / 会话接线在同目录的 `playback_engine_boundary_test.dart`。完整所有权及平台限制见 [播放架构](../../../docs/architecture/playback.md)，命令见 [测试指南](../../../docs/guides/testing.md)。
