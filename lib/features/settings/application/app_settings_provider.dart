import 'package:flutter/material.dart';
import 'package:mochi_player/core/domain/app_failure.dart';
import 'package:mochi_player/core/infrastructure/tmdb/tmdb_image_cache_manager.dart';
import 'package:mochi_player/core/infrastructure/tmdb/tmdb_service.dart';
import 'package:mochi_player/features/settings/domain/app_settings.dart';
import 'package:mochi_player/features/settings/infrastructure/app_settings_service.dart';

class AppSettingsProvider extends ChangeNotifier {
  final AppSettingsService _settingsService;

  AppSettingsProvider({AppSettingsService? settingsService})
    : _settingsService = settingsService ?? AppSettingsService();

  AppSettings _settings = const AppSettings();
  AppSettings? _appliedRuntimeSettings;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _shuttingDown = false;
  Future<void> _pendingSave = Future<void>.value();

  void beginShutdown() => _shuttingDown = true;

  Future<void> waitForPendingSave() => _pendingSave;
  AppFailure? _error;

  AppSettings get settings => _settings;

  AppSettings? get appliedRuntimeSettings => _appliedRuntimeSettings;

  bool get isLoading => _isLoading;

  bool get isSaving => _isSaving;

  AppFailure? get error => _error;

  String get tmdbApiKey => _settings.tmdbApiKey;

  String get tmdbApiBaseUrl => _settings.tmdbApiBaseUrl;

  String get tmdbProxyUrl => _settings.tmdbProxyUrl;

  bool get tmdbProxyEnabled => _settings.tmdbProxyEnabled;

  int get playbackCacheSizeMb => _settings.playbackCacheSizeMb;

  int get playbackReadaheadSeconds => _settings.playbackReadaheadSeconds;

  bool get enableHardwareAcceleration => _settings.enableHardwareAcceleration;

  String get subtitleLanguagePriority => _settings.subtitleLanguagePriority;

  double get subtitleFontSize => _settings.subtitleFontSize;

  bool get hasTmdbApiKey => _settings.hasTmdbApiKey;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _settings = await _settingsService.load();
      await _applyRuntimeSettings();
    } catch (e) {
      _error = AppFailure.settingsLoad;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveSettings({
    required String tmdbApiKey,
    required String tmdbApiBaseUrl,
    required String tmdbProxyUrl,
    required bool tmdbProxyEnabled,
    required int playbackCacheSizeMb,
    required int playbackReadaheadSeconds,
    required bool enableHardwareAcceleration,
    required String subtitleLanguagePriority,
    required double subtitleFontSize,
    bool applyRuntime = false,
  }) {
    if (_shuttingDown) return Future<void>.value();
    return _pendingSave = _pendingSave.then(
      (_) => _saveSettings(
        tmdbApiKey: tmdbApiKey,
        tmdbApiBaseUrl: tmdbApiBaseUrl,
        tmdbProxyUrl: tmdbProxyUrl,
        tmdbProxyEnabled: tmdbProxyEnabled,
        playbackCacheSizeMb: playbackCacheSizeMb,
        playbackReadaheadSeconds: playbackReadaheadSeconds,
        enableHardwareAcceleration: enableHardwareAcceleration,
        subtitleLanguagePriority: subtitleLanguagePriority,
        subtitleFontSize: subtitleFontSize,
        applyRuntime: applyRuntime,
      ),
    );
  }

  Future<void> _saveSettings({
    required String tmdbApiKey,
    required String tmdbApiBaseUrl,
    required String tmdbProxyUrl,
    required bool tmdbProxyEnabled,
    required int playbackCacheSizeMb,
    required int playbackReadaheadSeconds,
    required bool enableHardwareAcceleration,
    required String subtitleLanguagePriority,
    required double subtitleFontSize,
    bool applyRuntime = false,
  }) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final nextSettings = AppSettings(
        tmdbApiKey: tmdbApiKey.trim(),
        tmdbApiBaseUrl: tmdbApiBaseUrl.trim(),
        tmdbProxyUrl: tmdbProxyUrl.trim(),
        tmdbProxyEnabled: tmdbProxyEnabled,
        playbackCacheSizeMb: playbackCacheSizeMb,
        playbackReadaheadSeconds: playbackReadaheadSeconds,
        enableHardwareAcceleration: enableHardwareAcceleration,
        subtitleLanguagePriority: subtitleLanguagePriority.trim(),
        subtitleFontSize: subtitleFontSize,
      );
      _settings = await _settingsService.save(nextSettings);
      if (applyRuntime) await _applyRuntimeSettings();
    } catch (e) {
      _error = AppFailure.settingsSave;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> testTmdbConnection() async {
    if (!hasTmdbApiKey) return false;
    final result = await TmdbService().fetchTrendingMovies(limit: 1);
    return result.isNotEmpty;
  }

  Future<void> _applyRuntimeSettings() async {
    TmdbService().configure(
      apiKey: _settings.tmdbApiKey,
      apiBaseUrl: _settings.tmdbApiBaseUrl,
      proxyUrl: _settings.tmdbProxyUrl,
      proxyEnabled: _settings.tmdbProxyEnabled,
    );
    TmdbImageCacheManager.configure(proxyUrl: _settings.tmdbProxyUrl, proxyEnabled: _settings.tmdbProxyEnabled);

    _appliedRuntimeSettings = _settings;
  }
}
