// 【行为测试】验证串行创建、替换及关闭单个播放器视图。
// 测试对象的职责边界：通过注入的窗口工厂工作，重复请求不产生额外播放器。

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/features/playback/application/player_window_coordinator.dart';
import 'package:mochi_player/features/playback/domain/player_window_request.dart';

PlayerWindowRequest request(String id) => PlayerWindowRequest.fromPlayback(
  initialMedia: MediaFile(
    id: 1,
    sourceId: 'source',
    path: 'movie.mkv',
    fileName: 'movie.mkv',
    parsedTitle: 'Movie',
    addedAt: DateTime(2026),
  ),
  queue: const [],
  requestId: id,
);

class FakeSession implements PlayerWindowSession {
  final events = <String>[];
  Completer<void>? replacement;
  @override
  bool isClosing = false;
  @override
  Future<void> replace(PlayerWindowRequest request) async {
    events.add(request.requestId);
    await replacement?.future;
  }

  @override
  Future<void> activate() async => events.add('activate');
  @override
  Future<void> close() async {
    isClosing = true;
    events.add('close');
  }
}

void main() {
  test('concurrent launches create only one player and replace it in order', () async {
    final session = FakeSession();
    var created = 0;
    final coordinator = PlayerWindowCoordinator(
      createSession: (_) async {
        created++;
        return session;
      },
    );
    await Future.wait([coordinator.openOrReplace(request('first')), coordinator.openOrReplace(request('second'))]);
    expect(created, 1);
    expect(session.events, ['activate', 'second', 'activate']);
  });

  test('shutdown owns an in-flight creation and never activates its result', () async {
    final creation = Completer<PlayerWindowSession>();
    final coordinator = PlayerWindowCoordinator(createSession: (_) => creation.future);
    final launch = coordinator.openOrReplace(request('first'));
    final rejected = expectLater(launch, throwsStateError);
    await Future<void>.delayed(Duration.zero);
    final closing = coordinator.closeAll();
    final session = FakeSession();
    creation.complete(session);
    await Future.wait([rejected, closing]);
    expect(session.events, ['close']);
    await expectLater(coordinator.openOrReplace(request('late')), throwsStateError);
  });

  test('shutdown waits for replacement before releasing the session', () async {
    final session = FakeSession();
    final coordinator = PlayerWindowCoordinator(createSession: (_) async => session);
    await coordinator.openOrReplace(request('first'));
    session.replacement = Completer<void>();
    final launch = coordinator.openOrReplace(request('second'));
    final rejected = expectLater(launch, throwsStateError);
    await Future<void>.delayed(Duration.zero);
    final closing = coordinator.closeAll();
    expect(session.events, ['activate', 'second']);
    session.replacement!.complete();
    await Future.wait([rejected, closing]);
    expect(session.events, ['activate', 'second', 'close']);
  });

  test('a closed player is retired before reopening, without a second live session', () async {
    final sessions = <FakeSession>[];
    final coordinator = PlayerWindowCoordinator(
      createSession: (_) async {
        final session = FakeSession();
        sessions.add(session);
        return session;
      },
    );
    await coordinator.openOrReplace(request('first'));
    await sessions.single.close();
    await coordinator.openOrReplace(request('second'));
    expect(sessions.length, 2);
    expect(sessions.first.isClosing, isTrue);
    expect(sessions.last.events, ['activate']);
  });

  test('a failed replacement does not create another player and a later request can retry', () async {
    final session = FakeSession();
    var created = 0;
    final coordinator = PlayerWindowCoordinator(
      createSession: (_) async {
        created++;
        return session;
      },
    );
    await coordinator.openOrReplace(request('first'));
    session.replacement = Completer<void>();
    final failed = coordinator.openOrReplace(request('bad'));
    final rejected = expectLater(failed, throwsStateError);
    await Future<void>.delayed(Duration.zero);
    session.replacement!.completeError(StateError('unresolved media'));
    await rejected;
    session.replacement = null;
    await coordinator.openOrReplace(request('retry'));
    expect(created, 1);
    expect(session.events.last, 'activate');
  });
}
