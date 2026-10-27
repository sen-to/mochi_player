// 【窗口展示状态】保存启动请求与播放器窗口的展示状态。
// 实际引擎生命周期由播放会话管理，原生视图由窗口工厂创建。

import 'package:flutter/foundation.dart';
import 'package:mochi_player/core/domain/playback/playback_target_resolver.dart';
import 'package:mochi_player/features/playback/application/playback_media_repository.dart';
import 'package:mochi_player/features/playback/application/playback_session_controller.dart';
import 'package:mochi_player/features/playback/domain/player_window_request.dart';

class PlayerWindowController extends ChangeNotifier {
  PlayerWindowController(this._bootstrap);

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
  const PlayerWindowBootstrap._({required this.request, required this.mediaRepository, this.failure, this.playback});

  final PlayerWindowRequest request;
  final PlaybackMediaRepository mediaRepository;
  final PlayerLaunchFailure? failure;
  final PlaybackSessionController? playback;

  bool get isReady => failure == null && playback != null;

  static Future<PlayerWindowBootstrap> load(
    PlayerWindowRequest request, {
    required PlaybackMediaRepository mediaRepository,
    required PlaybackTargetResolver resolver,
  }) async {
    PlaybackSessionController? playback;
    try {
      final initialMedia =
          await mediaRepository.readMediaFile(
            sourceId: request.initialMedia.sourceId,
            path: request.initialMedia.path,
          ) ??
          request.initialMedia;
      final queue = await Future.wait(
        request.queue.map(
          (reference) async =>
              await mediaRepository.readMediaFile(sourceId: reference.sourceId, path: reference.path) ?? reference,
        ),
      );
      playback = PlaybackSessionController(
        mediaRepository: mediaRepository,
        initialItem: initialMedia,
        queueItems: queue,
        resolver: resolver,
      );
      final ready = await playback.prepare();
      return PlayerWindowBootstrap._(
        request: request,
        mediaRepository: mediaRepository,
        failure: ready ? null : PlayerLaunchFailure.target,
        playback: playback,
      );
    } catch (_) {
      await playback?.close();
      return PlayerWindowBootstrap._(
        request: request,
        mediaRepository: mediaRepository,
        failure: PlayerLaunchFailure.load,
      );
    }
  }
}
