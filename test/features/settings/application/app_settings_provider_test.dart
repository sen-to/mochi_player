import 'package:dio/dio.dart';
import 'package:mochi_player/core/domain/app_failure.dart';
import '../../../support/tmdb_fixture.dart';
import 'package:mochi_player/core/infrastructure/tmdb/tmdb_service.dart';
import 'package:mochi_player/features/settings/infrastructure/app_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/features/settings/application/app_settings_provider.dart';
import 'package:mochi_player/features/settings/domain/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final entry in {
    401: AppFailure.tmdbAuthentication,
    429: AppFailure.tmdbRateLimited,
    503: AppFailure.tmdbResponse,
  }.entries) {
    test('connection test reports ${entry.value} and clears it after success', () async {
      SharedPreferences.setMockInitialValues({'tmdb_api_key': 'key'});
      var status = entry.key;
      final tmdb = tmdbFixture(
        (request, handler) => handler.resolve(
          Response<dynamic>(
            requestOptions: request,
            statusCode: status,
            data: {
              'results': [
                {'id': 1, 'title': 'Movie'},
              ],
            },
          ),
        ),
      );
      final provider = AppSettingsProvider(settingsRepository: AppSettingsRepository(), tmdbService: tmdb);
      addTearDown(provider.dispose);
      await provider.load();
      expect(await provider.testTmdbConnection(), isFalse);
      expect(provider.error, entry.value);
      status = 200;
      expect(await provider.testTmdbConnection(), isTrue);
      expect(provider.error, isNull);
    });
  }

  test('runtime network changes notify the application without a settings page', () async {
    SharedPreferences.setMockInitialValues({});
    var changes = 0;
    final provider = AppSettingsProvider(
      settingsRepository: AppSettingsRepository(),
      tmdbService: TmdbService(),
      onTmdbConfigurationChanged: () => changes++,
    );
    addTearDown(provider.dispose);
    await provider.load();
    expect(changes, 0);
    await _save(provider, tmdbApiKey: 'draft');
    expect(changes, 0);
    await _save(provider, tmdbApiKey: 'applied', applyRuntime: true);
    expect(changes, 1);
    await _save(provider, tmdbApiKey: 'applied', applyRuntime: true);
    expect(changes, 1);
    await _save(provider, tmdbApiKey: '', applyRuntime: true);
    expect(changes, 2);
  });

  test('failed persistence does not apply runtime configuration or notify the home owner', () async {
    SharedPreferences.setMockInitialValues({});
    var changes = 0;
    final provider = AppSettingsProvider(
      settingsRepository: _FailingSettingsRepository(),
      tmdbService: TmdbService(),
      onTmdbConfigurationChanged: () => changes++,
    );
    addTearDown(provider.dispose);
    await provider.load();
    await _save(provider, tmdbApiKey: 'rejected', applyRuntime: true);
    expect(provider.error, AppFailure.settingsSave);
    expect(provider.appliedRuntimeSettings?.tmdbApiKey, isEmpty);
    expect(changes, 0);
  });

  test('exit does not start a home refresh for an accepted save', () async {
    SharedPreferences.setMockInitialValues({});
    var changes = 0;
    final provider = AppSettingsProvider(
      settingsRepository: AppSettingsRepository(),
      tmdbService: TmdbService(),
      onTmdbConfigurationChanged: () => changes++,
    );
    addTearDown(provider.dispose);
    await provider.load();
    final saving = _save(provider, tmdbApiKey: 'accepted', applyRuntime: true);
    provider.beginShutdown();
    await saving;
    expect(provider.tmdbApiKey, 'accepted');
    expect(changes, 0);
  });

  test('exit drains accepted settings saves and rejects new drafts', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = AppSettingsProvider(settingsRepository: AppSettingsRepository(), tmdbService: TmdbService());
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
    final provider = AppSettingsProvider(settingsRepository: AppSettingsRepository(), tmdbService: TmdbService());
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

class _FailingSettingsRepository extends AppSettingsRepository {
  @override
  Future<AppSettings> save(AppSettings settings) async => throw StateError('settings write failed');
}
