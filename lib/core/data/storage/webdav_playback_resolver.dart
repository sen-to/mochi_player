// 【播放地址适配】生成 WebDAV 文件地址及认证请求头。
// 只解析目标，不创建播放器或保存播放进度。

import 'dart:convert';

import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/playback/playback_target.dart';
import 'package:mochi_player/core/domain/playback/playback_target_resolver.dart';
import 'package:mochi_player/core/domain/storage/models.dart';

/// 解析标准 WebDAV 来源中的文件，不依赖特定服务商接口。
class WebDavPlaybackResolver implements PlaybackTargetResolver {
  final StorageSource source;
  final StorageCredentials? credentials;

  WebDavPlaybackResolver({required this.source, this.credentials}) {
    if (source.type != StorageSourceType.webDav) {
      throw ArgumentError.value(source.type, 'source.type', 'must be WebDAV');
    }
  }

  @override
  Future<PlaybackTarget?> resolve(MediaFile file) async {
    if (file.sourceId != source.id) {
      return null;
    }
    final endpoint = Uri.tryParse(source.endpoint.trim());
    if (endpoint == null || !endpoint.hasScheme || endpoint.host.isEmpty) {
      return null;
    }

    final target = endpoint.replace(
      pathSegments: [
        ...endpoint.pathSegments.where((segment) => segment.isNotEmpty),
        ..._pathSegments(source.rootPath),
        ..._pathSegments(file.path),
      ],
    );
    return PlaybackTarget(url: target.toString(), httpHeaders: _authorizationHeader());
  }

  Map<String, String> _authorizationHeader() {
    final username = credentials?.username ?? '';
    final password = credentials?.password ?? '';
    if (username.isEmpty && password.isEmpty) return const {};
    final value = base64Encode(utf8.encode('$username:$password'));
    return {'Authorization': 'Basic $value'};
  }

  Iterable<String> _pathSegments(String path) {
    return path.split('/').where((segment) => segment.isNotEmpty);
  }
}
