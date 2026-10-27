// 【运行时适配】应用 TMDB 与图片代理配置，并转换连接测试失败。
// 不保存偏好或通知页面，运行时参数由应用层提供。

import 'package:mochi_player/core/data/tmdb/tmdb_api.dart';
import 'package:mochi_player/core/data/tmdb/tmdb_failure.dart';
import 'package:mochi_player/core/data/tmdb/tmdb_image_cache_manager.dart';
import 'package:mochi_player/features/settings/application/app_settings_runtime.dart';
import 'package:mochi_player/features/settings/domain/app_settings.dart';

class TmdbSettingsRuntime implements AppSettingsRuntime {
  TmdbSettingsRuntime({required TmdbApi tmdbApi}) : _api = tmdbApi;
  final TmdbApi _api;
  @override
  void apply(AppSettings settings) {
    _api.configure(
      apiKey: settings.tmdbApiKey,
      apiBaseUrl: settings.tmdbApiBaseUrl,
      proxyUrl: settings.tmdbProxyUrl,
      proxyEnabled: settings.tmdbProxyEnabled,
    );
    TmdbImageCacheManager.configure(proxyUrl: settings.tmdbProxyUrl, proxyEnabled: settings.tmdbProxyEnabled);
  }

  @override
  Future<bool> testTmdbConnection() async {
    try {
      if (!_api.isConfigured) throw const TmdbFailure(TmdbFailureKind.configuration);
      return (await _api.fetchTrendingMovies(limit: 1)).isNotEmpty;
    } on TmdbFailure catch (failure) {
      throw SettingsConnectionFailure(failure.userFailure);
    }
  }
}
