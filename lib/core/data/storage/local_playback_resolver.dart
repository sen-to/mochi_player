// 【播放地址适配】将来源内文件解析为本地文件 URL。
// 校验文件位于来源根目录内，不持有播放引擎。

import 'dart:io';

import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/playback/playback_target.dart';
import 'package:mochi_player/core/domain/playback/playback_target_resolver.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:path/path.dart' as path;

/// 将来源相对路径的媒体文件解析为本地 file URL。
class LocalPlaybackResolver implements PlaybackTargetResolver {
  LocalPlaybackResolver({required this.source});

  final StorageSource source;

  @override
  Future<PlaybackTarget?> resolve(MediaFile file) async {
    if (source.type != StorageSourceType.local || file.sourceId != source.id) {
      return null;
    }
    final root = source.endpoint.trim();
    if (root.isEmpty || !path.isAbsolute(root)) return null;
    final relativePath = file.path.replaceFirst(RegExp(r'^/+'), '');
    final resolved = path.normalize(path.join(root, relativePath));
    if (resolved != path.normalize(root) && !path.isWithin(root, resolved)) {
      return null;
    }
    return PlaybackTarget(url: File(resolved).uri.toString());
  }
}
