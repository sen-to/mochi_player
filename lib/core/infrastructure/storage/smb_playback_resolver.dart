import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/playback/playback_target.dart';
import 'package:mochi_player/core/domain/playback/playback_target_resolver.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/domain/storage/smb_source_location.dart';

/// Resolves SMB media into an URL that libmpv opens and streams directly.
///
/// This deliberately does not download files into a local cache: once the
/// bundled libmpv has SMB support, it owns buffering and seeking just like it
/// does for any other network source.
class SmbPlaybackResolver implements PlaybackTargetResolver {
  const SmbPlaybackResolver({required this.source, this.credentials});

  final StorageSource source;
  final StorageCredentials? credentials;

  @override
  Future<PlaybackTarget?> resolve(MediaFile file) async {
    if (source.type != StorageSourceType.smb || file.sourceId != source.id) {
      return null;
    }
    final location = SmbSourceLocation.fromSource(source);
    final username = credentials?.username.trim() ?? '';
    final password = credentials?.password ?? '';
    final userInfo = username.isEmpty
        ? null
        : password.isEmpty
        ? username
        : '$username:$password';

    return PlaybackTarget(
      url: Uri(
        scheme: 'smb',
        userInfo: userInfo,
        host: location.host,
        pathSegments: [location.share, ...location.resolve(file.path).split('/')],
      ).toString(),
    );
  }
}
