import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/playback/playback_target.dart';
import 'package:mochi_player/core/domain/playback/playback_target_resolver.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/domain/storage/smb_source_location.dart';
import 'package:mochi_player/core/infrastructure/storage/smb_http_playback_proxy.dart';
import 'package:mochi_player/core/infrastructure/storage/smb_media_reader.dart';

/// Opens an SMB file and exposes only that file through a local HTTP session.
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
