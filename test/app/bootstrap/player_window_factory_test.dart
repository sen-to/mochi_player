import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/app/bootstrap/player_window_factory.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/playback/playback_target.dart';
import 'package:mochi_player/core/domain/playback/playback_target_resolver.dart';
import 'package:mochi_player/core/platform/desktop_window_service.dart';
import 'package:mochi_player/core/platform/window_service.dart';
import 'package:mochi_player/features/playback/application/playback_media_repository.dart';
import 'package:mochi_player/features/playback/domain/player_window_request.dart';

void main() {
  test('native window creation failure closes the prepared session without creating an engine', () async {
    final file = MediaFile(id: 1, path: '/one', fileName: 'one', parsedTitle: 'One', addedAt: DateTime(2026));
    final resource = _Resource();
    var engineCreations = 0;
    await expectLater(
      createPlayerWindow(
        host: _FailingHost(),
        request: PlayerWindowRequest.fromPlayback(initialMedia: file, queue: [file]),
        mediaRepository: _Repository(),
        resolver: _Resolver(resource),
        engineFactory: (_) {
          engineCreations++;
          throw StateError('Engine must not be created without a view');
        },
      ),
      throwsStateError,
    );
    expect(resource.closeCalls, 1);
    expect(engineCreations, 0);
  });
}

class _FailingHost extends DesktopWindowHost {
  @override
  WindowService create({required WindowSetup setup, required WidgetBuilder builder}) =>
      throw StateError('Native window unavailable');
}

class _Repository implements PlaybackMediaRepository {
  @override
  Future<MediaFile?> readMediaFile({required String sourceId, required String path}) async => null;
  @override
  Future<void> updateProgress(MediaFile file, int position, {int? duration}) async {}
}

class _Resolver implements PlaybackTargetResolver {
  _Resolver(this.resource);
  final _Resource resource;
  @override
  Future<PlaybackTarget?> resolve(MediaFile file) async =>
      PlaybackTarget(url: 'http://127.0.0.1/video', resource: resource);
}

class _Resource implements PlaybackTargetResource {
  int closeCalls = 0;
  @override
  Future<void> close() async => closeCalls++;
}
