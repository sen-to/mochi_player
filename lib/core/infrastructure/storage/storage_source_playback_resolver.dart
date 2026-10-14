import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/playback/playback_target.dart';
import 'package:mochi_player/core/domain/playback/playback_target_resolver.dart';
import 'package:mochi_player/core/domain/storage/storage_source_type.dart';
import 'package:mochi_player/core/infrastructure/storage/local_playback_resolver.dart';
import 'package:mochi_player/core/infrastructure/storage/smb_playback_resolver.dart';
import 'package:mochi_player/core/infrastructure/storage/storage_source_repository.dart';
import 'package:mochi_player/core/infrastructure/storage/webdav_playback_resolver.dart';

/// Resolves playback through the source that owns a media file.
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
