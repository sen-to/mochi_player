import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/features/settings/application/app_settings_provider.dart';
import 'package:mochi_player/features/settings/domain/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('exit drains accepted settings saves and rejects new drafts', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = AppSettingsProvider();
    await provider.load();
    final first = _save(provider, tmdbApiKey: 'first');
    final second = _save(provider, tmdbApiKey: 'last-accepted');
    provider.beginShutdown();
    await _save(provider, tmdbApiKey: 'rejected');
    await provider.waitForPendingSave();
    await Future.wait([first, second]);
    expect(provider.tmdbApiKey, 'last-accepted');
    expect((await SharedPreferences.getInstance()).getString('tmdb_api_key'), 'last-accepted');
  });

  test('persists drafts without applying network runtime configuration', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = AppSettingsProvider();
    await provider.load();

    await _save(provider, tmdbApiKey: 'draft-key');

    expect(provider.tmdbApiKey, 'draft-key');
    expect(provider.appliedRuntimeSettings?.tmdbApiKey, isEmpty);

    await _save(provider, tmdbApiKey: 'committed-key', applyRuntime: true);

    expect(provider.tmdbApiKey, 'committed-key');
    expect(provider.appliedRuntimeSettings?.tmdbApiKey, 'committed-key');
  });
}

Future<void> _save(AppSettingsProvider provider, {required String tmdbApiKey, bool applyRuntime = false}) {
  return provider.saveSettings(
    tmdbApiKey: tmdbApiKey,
    tmdbApiBaseUrl: AppSettings.defaultTmdbApiBaseUrl,
    tmdbProxyUrl: '',
    tmdbProxyEnabled: AppSettings.defaultTmdbProxyEnabled,
    playbackCacheSizeMb: AppSettings.defaultPlaybackCacheSizeMb,
    playbackReadaheadSeconds: AppSettings.defaultPlaybackReadaheadSeconds,
    enableHardwareAcceleration: AppSettings.defaultEnableHardwareAcceleration,
    subtitleLanguagePriority: AppSettings.defaultSubtitleLanguagePriority,
    subtitleFontSize: AppSettings.defaultSubtitleFontSize,
    applyRuntime: applyRuntime,
  );
}
