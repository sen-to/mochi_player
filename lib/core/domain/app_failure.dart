// 【失败模型】定义面向界面的失败语义。
// 本地化由展示入口处理，底层异常保留在诊断日志。

/// 面向用户的失败只携带语义编码；诊断异常保留在日志中。
enum AppFailure {
  settingsLoad,
  settingsSave,
  sourceRequired,
  filesLoad,
  scanSourceRequired,
  scanFailed,
  scrapeFailed,
  tmdbAuthentication,
  tmdbRateLimited,
  tmdbTimeout,
  tmdbNetwork,
  tmdbResponse,
  contentLoad,
  playbackLink,
  playbackOpen,
  playerLaunch,
}
