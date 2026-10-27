// 【播放地址分派】根据文件所属媒体源选择本地、WebDAV 或 SMB 解析。
// 解析结果交给播放会话持有，不在页面内读取凭据。

import 'package:mochi_player/core/data/storage/local_playback_resolver.dart';
import 'package:mochi_player/core/data/storage/smb_playback_resolver.dart';
import 'package:mochi_player/core/data/storage/webdav_playback_resolver.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/playback/playback_target.dart';
import 'package:mochi_player/core/domain/playback/playback_target_resolver.dart';
import 'package:mochi_player/core/domain/storage/storage_source_repository.dart';
import 'package:mochi_player/core/domain/storage/storage_source_type.dart';

/// 通过媒体文件所属的来源解析播放目标。
class StorageSourcePlaybackResolver implements PlaybackTargetResolver {
  final StorageSourceRepository _repository;

  StorageSourcePlaybackResolver({required StorageSourceRepository repository}) : _repository = repository;

  @override
  Future<PlaybackTarget?> resolve(MediaFile file) async {
    final source = await _repository.getById(file.sourceId);
    if (source == null) return null;
    if (!source.enabled) return null;

    return switch (source.type) {
      StorageSourceType.local => LocalPlaybackResolver(source: source).resolve(file),
      StorageSourceType.webDav => WebDavPlaybackResolver(
        source: source,
        credentials: await _repository.readCredentials(source.id),
      ).resolve(file),
      StorageSourceType.smb => SmbPlaybackResolver(
        source: source,
        credentials: await _repository.readCredentials(source.id),
      ).resolve(file),
    };
  }
}
