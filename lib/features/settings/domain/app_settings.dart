// 【设置模型】定义普通偏好、播放默认值、边界及规范化规则。
// 比较已生效的 TMDB 配置时只关注网络相关字段。

/// 持久化的应用设置及播放默认值。
class AppSettings {
  static const defaultPlaybackCacheSizeMb = 256;
  static const defaultPlaybackReadaheadSeconds = 60;
  static const minPlaybackCacheSizeMb = 16;
  static const maxPlaybackCacheSizeMb = 4096;
  static const minPlaybackReadaheadSeconds = 5;
  static const maxPlaybackReadaheadSeconds = 1800;
  static const defaultEnableHardwareAcceleration = true;
  static const defaultSubtitleLanguagePriority = 'zh,chi,zho,chs,cht,eng';
  static const defaultSubtitleFontSize = 24.0;
  static const defaultTmdbApiBaseUrl = 'https://api.themoviedb.org/3';
  static const defaultTmdbProxyEnabled = false;

  final String tmdbApiKey;
  final String tmdbApiBaseUrl;
  final String tmdbProxyUrl;
  final bool tmdbProxyEnabled;
  final int playbackCacheSizeMb;
  final int playbackReadaheadSeconds;
  final bool enableHardwareAcceleration;
  final String subtitleLanguagePriority;
  final double subtitleFontSize;

  const AppSettings({
    this.tmdbApiKey = '',
    this.tmdbApiBaseUrl = defaultTmdbApiBaseUrl,
    this.tmdbProxyUrl = '',
    this.tmdbProxyEnabled = defaultTmdbProxyEnabled,
    this.playbackCacheSizeMb = defaultPlaybackCacheSizeMb,
    this.playbackReadaheadSeconds = defaultPlaybackReadaheadSeconds,
    this.enableHardwareAcceleration = defaultEnableHardwareAcceleration,
    this.subtitleLanguagePriority = defaultSubtitleLanguagePriority,
    this.subtitleFontSize = defaultSubtitleFontSize,
  });

  bool hasSameTmdbConfiguration(AppSettings other) =>
      tmdbApiKey == other.tmdbApiKey &&
      tmdbApiBaseUrl == other.tmdbApiBaseUrl &&
      tmdbProxyUrl == other.tmdbProxyUrl &&
      tmdbProxyEnabled == other.tmdbProxyEnabled;

  bool get hasTmdbApiKey => tmdbApiKey.trim().isNotEmpty;

  int get playbackCacheMaxBytes => playbackCacheSizeMb * 1024 * 1024;

  String get normalizedSubtitleLanguagePriority =>
      _normalizeLanguagePriority(subtitleLanguagePriority, defaultSubtitleLanguagePriority);

  /// 规范化可保存的设置输入；范围与默认值规则只在领域模型中维护。
  AppSettings normalized() => AppSettings(
    tmdbApiKey: tmdbApiKey.trim(),
    tmdbApiBaseUrl: tmdbApiBaseUrl.trim().isEmpty ? AppSettings.defaultTmdbApiBaseUrl : tmdbApiBaseUrl.trim(),
    tmdbProxyUrl: tmdbProxyUrl.trim(),
    tmdbProxyEnabled: tmdbProxyEnabled,
    playbackCacheSizeMb: playbackCacheSizeMb
        .clamp(AppSettings.minPlaybackCacheSizeMb, AppSettings.maxPlaybackCacheSizeMb)
        .toInt(),
    playbackReadaheadSeconds: playbackReadaheadSeconds
        .clamp(AppSettings.minPlaybackReadaheadSeconds, AppSettings.maxPlaybackReadaheadSeconds)
        .toInt(),
    enableHardwareAcceleration: enableHardwareAcceleration,
    subtitleLanguagePriority: subtitleLanguagePriority.trim(),
    subtitleFontSize: subtitleFontSize.clamp(18.0, 40.0).toDouble(),
  );

  static String _normalizeLanguagePriority(String value, String fallback) {
    final parts = value.split(',').map((part) => part.trim()).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return fallback;
    return parts.join(',');
  }
}
