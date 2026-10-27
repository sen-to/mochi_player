// 【播放资源适配】打开单个 SMB 文件并创建本机 HTTP 播放目标。
// 初始化失败自行清理；成功后的资源由播放会话接管。

import 'package:mochi_player/core/data/storage/smb_http_playback_proxy.dart';
import 'package:mochi_player/core/data/storage/smb_media_reader.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/playback/playback_target.dart';
import 'package:mochi_player/core/domain/playback/playback_target_resolver.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/domain/storage/smb_source_location.dart';

/// 打开一个 SMB 文件，并通过本机 HTTP 会话只暴露该文件。
class SmbPlaybackResolver implements PlaybackTargetResolver {
  const SmbPlaybackResolver({required this.source, this.credentials, this.openReader = Smb2MediaReader.open});

  final StorageSource source;
  final StorageCredentials? credentials;
  final Future<SmbMediaReader> Function(SmbSourceLocation, StorageCredentials?, String) openReader;

  @override
  Future<PlaybackTarget?> resolve(MediaFile file) async {
    if (source.type != StorageSourceType.smb || file.sourceId != source.id) return null;
    final reader = await openReader(SmbSourceLocation.fromSource(source), credentials, file.path);
    final proxy = await SmbHttpPlaybackProxy.start(reader);
    return PlaybackTarget(url: proxy.uri.toString(), resource: proxy);
  }
}
