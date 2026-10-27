// 【运行时契约】定义偏好生效和网络连接验证能力。
// 设置状态不接触具体 HTTP 客户端或图片缓存实现。

import 'package:mochi_player/core/domain/app_failure.dart';
import 'package:mochi_player/features/settings/domain/app_settings.dart';

abstract interface class AppSettingsRuntime {
  void apply(AppSettings settings);
  Future<bool> testTmdbConnection();
}

class SettingsConnectionFailure implements Exception {
  const SettingsConnectionFailure(this.failure);
  final AppFailure failure;
}
