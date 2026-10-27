/// Persisted application settings and playback defaults.
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

  AppSettings withFallbacks(AppSettings fallback) {
    return AppSettings(
      tmdbApiKey: tmdbApiKey.trim().isNotEmpty ? tmdbApiKey : fallback.tmdbApiKey,
      tmdbApiBaseUrl: tmdbApiBaseUrl.trim().isNotEmpty ? tmdbApiBaseUrl : fallback.tmdbApiBaseUrl,
      tmdbProxyUrl: tmdbProxyUrl.trim(),
      tmdbProxyEnabled: tmdbProxyEnabled,
      playbackCacheSizeMb: playbackCacheSizeMb.clamp(minPlaybackCacheSizeMb, maxPlaybackCacheSizeMb).toInt(),
      playbackReadaheadSeconds: playbackReadaheadSeconds
          .clamp(minPlaybackReadaheadSeconds, maxPlaybackReadaheadSeconds)
          .toInt(),
      enableHardwareAcceleration: enableHardwareAcceleration,
      subtitleLanguagePriority: _normalizeLanguagePriority(subtitleLanguagePriority, fallback.subtitleLanguagePriority),
      subtitleFontSize: subtitleFontSize.clamp(18.0, 40.0).toDouble(),
    );
  }

  static String _normalizeLanguagePriority(String value, String fallback) {
    final parts = value.split(',').map((part) => part.trim()).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return fallback;
    return parts.join(',');
  }
}
