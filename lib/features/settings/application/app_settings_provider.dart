// 【界面状态与应用入口】加载、串行保存普通偏好并应用运行时网络配置。
// 配置生效后发出变更回调，不依赖首页页面或趋势 Provider。

import 'package:flutter/foundation.dart';
import 'package:mochi_player/core/domain/app_failure.dart';
import 'package:mochi_player/features/settings/application/app_settings_repository.dart';
import 'package:mochi_player/features/settings/application/app_settings_runtime.dart';
import 'package:mochi_player/features/settings/domain/app_settings.dart';

class AppSettingsProvider extends ChangeNotifier {
  final AppSettingsRepository _settingsRepository;

  AppSettingsProvider({
    required AppSettingsRepository settingsRepository,
    required AppSettingsRuntime runtime,
    VoidCallback? onTmdbConfigurationChanged,
  }) : _settingsRepository = settingsRepository,
       _runtime = runtime,
       _onTmdbConfigurationChanged = onTmdbConfigurationChanged;

  final AppSettingsRuntime _runtime;
  final VoidCallback? _onTmdbConfigurationChanged;

  AppSettings _settings = const AppSettings();
  AppSettings? _appliedRuntimeSettings;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _shuttingDown = false;
  bool _disposed = false;
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
    if (_shuttingDown) return;
    _isLoading = true;
    _error = null;
    if (!_disposed) notifyListeners();

    try {
      final settings = await _settingsRepository.load();
      if (_disposed) return;
      _settings = settings;
      await _applyRuntimeSettings();
    } catch (e) {
      _error = AppFailure.settingsLoad;
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
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
    if (!_disposed) notifyListeners();

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
      _settings = await _settingsRepository.save(nextSettings);
      if (applyRuntime) await _applyRuntimeSettings();
    } catch (e) {
      _error = AppFailure.settingsSave;
    } finally {
      _isSaving = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> testTmdbConnection() async {
    if (_shuttingDown) return false;
    _error = null;
    try {
      return await _runtime.testTmdbConnection();
    } on SettingsConnectionFailure catch (failure) {
      _error = failure.failure;
      return false;
    } finally {
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    beginShutdown();
    super.dispose();
  }

  Future<void> _applyRuntimeSettings() async {
    if (_disposed) return;
    final previous = _appliedRuntimeSettings;
    _runtime.apply(_settings);

    _appliedRuntimeSettings = _settings;
    // 初次加载后由首页启动流程加载趋势；只保存草稿或只修改播放设置，不需要使首页集合失效。
    if (!_shuttingDown && previous != null && !previous.hasSameTmdbConfiguration(_settings)) {
      _onTmdbConfigurationChanged?.call();
    }
  }
}
