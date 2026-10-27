// 【数据访问】从偏好存储加载和保存普通应用设置。
// 不负责网络配置生效或界面通知。

import 'package:mochi_player/features/settings/application/app_settings_repository.dart';
import 'package:mochi_player/features/settings/domain/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesAppSettingsRepository implements AppSettingsRepository {
  static const _tmdbApiKeyKey = 'tmdb_api_key';
  static const _tmdbApiBaseUrlKey = 'tmdb_api_base_url';
  static const _tmdbProxyUrlKey = 'tmdb_proxy_url';
  static const _tmdbProxyEnabledKey = 'tmdb_proxy_enabled';
  static const _playbackCacheSizeMbKey = 'playback_cache_size_mb';
  static const _playbackReadaheadSecondsKey = 'playback_readahead_seconds';
  static const _enableHardwareAccelerationKey = 'enable_hardware_acceleration';
  static const _subtitleLanguagePriorityKey = 'subtitle_language_priority';
  static const _subtitleFontSizeKey = 'subtitle_font_size';
  PreferencesAppSettingsRepository();

  @override
  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      tmdbApiKey: prefs.getString(_tmdbApiKeyKey) ?? '',
      tmdbApiBaseUrl: prefs.getString(_tmdbApiBaseUrlKey) ?? AppSettings.defaultTmdbApiBaseUrl,
      tmdbProxyUrl: prefs.getString(_tmdbProxyUrlKey) ?? '',
      tmdbProxyEnabled: prefs.getBool(_tmdbProxyEnabledKey) ?? AppSettings.defaultTmdbProxyEnabled,
      playbackCacheSizeMb: prefs.getInt(_playbackCacheSizeMbKey) ?? AppSettings.defaultPlaybackCacheSizeMb,
      playbackReadaheadSeconds:
          prefs.getInt(_playbackReadaheadSecondsKey) ?? AppSettings.defaultPlaybackReadaheadSeconds,
      enableHardwareAcceleration:
          prefs.getBool(_enableHardwareAccelerationKey) ?? AppSettings.defaultEnableHardwareAcceleration,
      subtitleLanguagePriority:
          prefs.getString(_subtitleLanguagePriorityKey) ?? AppSettings.defaultSubtitleLanguagePriority,
      subtitleFontSize: prefs.getDouble(_subtitleFontSizeKey) ?? AppSettings.defaultSubtitleFontSize,
    );
  }

  @override
  Future<AppSettings> save(AppSettings settings) async {
    final settingsToSave = settings.normalized();
    final prefs = await SharedPreferences.getInstance();
    await _requireSaved(prefs.setString(_tmdbApiKeyKey, settingsToSave.tmdbApiKey.trim()));
    await _requireSaved(prefs.setString(_tmdbApiBaseUrlKey, settingsToSave.tmdbApiBaseUrl));
    await _requireSaved(prefs.setString(_tmdbProxyUrlKey, settingsToSave.tmdbProxyUrl));
    await _requireSaved(prefs.setBool(_tmdbProxyEnabledKey, settingsToSave.tmdbProxyEnabled));
    await _requireSaved(prefs.setInt(_playbackCacheSizeMbKey, settingsToSave.playbackCacheSizeMb));
    await _requireSaved(prefs.setInt(_playbackReadaheadSecondsKey, settingsToSave.playbackReadaheadSeconds));
    await _requireSaved(prefs.setBool(_enableHardwareAccelerationKey, settingsToSave.enableHardwareAcceleration));
    await _requireSaved(prefs.setString(_subtitleLanguagePriorityKey, settingsToSave.subtitleLanguagePriority));
    await _requireSaved(prefs.setDouble(_subtitleFontSizeKey, settingsToSave.subtitleFontSize));
    return settingsToSave;
  }

  // 插件可能返回 false 而不抛异常，不能据此向调用方报告保存成功。
  Future<void> _requireSaved(Future<bool> write) async {
    if (!await write) throw StateError('应用设置未能保存');
  }
}
