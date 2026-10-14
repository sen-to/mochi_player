import 'package:flutter/foundation.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/playback/playback_target.dart';
import 'package:mochi_player/core/domain/playback/playback_target_resolver.dart';
import 'package:mochi_player/features/playback/application/playback_media_store.dart';
import 'package:mochi_player/features/playback/domain/player_window_request.dart';

class PlayerWindowState extends ChangeNotifier {
  PlayerWindowState(this._bootstrap);

  PlayerWindowBootstrap _bootstrap;
  bool _isOpen = true;
  bool _acceptRequests = true;

  void beginShutdown() {
    if (!_acceptRequests) return;
    _acceptRequests = false;
    notifyListeners();
  }

  bool get isClosing => !_acceptRequests;

  PlayerWindowBootstrap get bootstrap => _bootstrap;

  bool get isOpen => _isOpen;

  void open(PlayerWindowBootstrap next) {
    if (!_acceptRequests) return;
    _bootstrap = next;
    _isOpen = true;
    notifyListeners();
  }

  void close() {
    if (!_isOpen) return;
    _isOpen = false;
    notifyListeners();
  }
}

enum PlayerLaunchFailure { load, target }

class PlayerWindowBootstrap {
  const PlayerWindowBootstrap._({
    required this.request,
    required this.mediaStore,
    this.failure,
    this.initialMedia,
    this.queue = const [],
    this.initialTarget,
  });

  final PlayerWindowRequest request;
  final PlaybackMediaStore mediaStore;
  final PlayerLaunchFailure? failure;
  final MediaFile? initialMedia;
  final List<MediaFile> queue;
  final PlaybackTarget? initialTarget;

  bool get isReady => initialMedia != null && initialTarget != null;

  static Future<PlayerWindowBootstrap> load(
    PlayerWindowRequest request, {
    required PlaybackMediaStore mediaStore,
    required PlaybackTargetResolver resolver,
  }) async {
    try {
      final persistedInitialMedia = await mediaStore.readMediaFile(
        sourceId: request.initialMedia.sourceId,
        path: request.initialMedia.path,
      );
      final initialMedia = persistedInitialMedia ?? request.initialMedia;
      final queue = (await Future.wait(
        request.queue.map(
          (reference) async =>
              await mediaStore.readMediaFile(sourceId: reference.sourceId, path: reference.path) ?? reference,
        ),
      )).toList(growable: false);
      final target = await resolver.resolve(initialMedia);
      return PlayerWindowBootstrap._(
        request: request,
        mediaStore: mediaStore,
        failure: target == null ? PlayerLaunchFailure.target : null,
        initialMedia: initialMedia,
        queue: queue,
        initialTarget: target,
      );
    } catch (error) {
      return PlayerWindowBootstrap._(request: request, mediaStore: mediaStore, failure: PlayerLaunchFailure.load);
    }
  }
}
