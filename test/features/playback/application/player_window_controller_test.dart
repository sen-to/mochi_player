// 【行为测试】验证保存启动请求与播放器窗口的展示状态。
// 测试对象的职责边界：实际引擎生命周期由播放会话管理，原生视图由窗口工厂创建。

import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/playback/playback_target.dart';
import 'package:mochi_player/core/domain/playback/playback_target_resolver.dart';
import 'package:mochi_player/features/playback/application/playback_media_repository.dart';
import 'package:mochi_player/features/playback/application/player_window_controller.dart';
import 'package:mochi_player/features/playback/domain/player_window_request.dart';

void main() {
  final original = MediaFile(
    id: 1,
    sourceId: 'source',
    path: '/video',
    fileName: 'video',
    parsedTitle: 'Video',
    addedAt: DateTime(2026),
  );
  final request = PlayerWindowRequest.fromPlayback(initialMedia: original, queue: [original]);
  test('bootstrap refreshes persisted progress and forwards the fresh item to the injected resolver', () async {
    final fresh = original.copyWith(position: 42000, duration: 100000);
    final resolver = _Resolver();
    final result = await PlayerWindowBootstrap.load(request, mediaRepository: _Repository(fresh), resolver: resolver);
    expect(result.playback!.currentItem.position, 42000);
    expect(resolver.resolved!.position, 42000);
    expect(result.isReady, isTrue);
  });
  test('bootstrap retains browser-only files and distinguishes unresolved targets from load errors', () async {
    final unresolved = await PlayerWindowBootstrap.load(
      request,
      mediaRepository: _Repository(null),
      resolver: _Resolver(available: false),
    );
    expect(unresolved.playback!.currentItem, same(original));
    expect(unresolved.failure, PlayerLaunchFailure.target);
    final failed = await PlayerWindowBootstrap.load(
      request,
      mediaRepository: _Repository(null, fail: true),
      resolver: _Resolver(),
    );
    expect(failed.failure, PlayerLaunchFailure.load);
  });
  test('closing state rejects a later replacement even when it finishes loading', () async {
    final loaded = await PlayerWindowBootstrap.load(request, mediaRepository: _Repository(null), resolver: _Resolver());
    final state = PlayerWindowController(loaded);
    state.beginShutdown();
    state.close();
    state.open(loaded);
    expect(state.isClosing, isTrue);
    expect(state.isOpen, isFalse);
    state.dispose();
  });
}

class _Repository implements PlaybackMediaRepository {
  _Repository(this.file, {this.fail = false});
  final MediaFile? file;
  final bool fail;
  @override
  Future<MediaFile?> readMediaFile({required String sourceId, required String path}) async {
    if (fail) throw StateError('read failed');
    return file;
  }

  @override
  Future<void> updateProgress(MediaFile file, int position, {int? duration}) async {}
}

class _Resolver implements PlaybackTargetResolver {
  _Resolver({this.available = true});
  final bool available;
  MediaFile? resolved;
  @override
  Future<PlaybackTarget?> resolve(MediaFile file) async {
    resolved = file;
    return available ? const PlaybackTarget(url: 'file:///video') : null;
  }
}
