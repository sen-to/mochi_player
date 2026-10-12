import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/platform/window_service.dart';
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

class FakeWindows extends WindowService {
  final List<FakeWindow> all = [];
  final List<String> events = [];
  Completer<WindowHandle>? creation;
  int created = 0;
  @override
  Future<List<WindowHandle>> getAll() async => List.of(all);
  @override
  Future<WindowHandle> create(String arguments) async {
    created++;
    if (creation != null) return creation!.future;
    final window = FakeWindow(this, 'player-$created', arguments);
    all.add(window);
    return window;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeWindow implements WindowHandle {
  FakeWindow(this.windows, this.id, this.arguments);
  final FakeWindows windows;
  @override
  final String id;
  @override
  final String arguments;
  Future<Object?> Function(MethodCall)? handler;
  Completer<void>? save;
  bool rejectReplace = false;
  @override
  Future<T?> invoke<T>(String method, [Object? arguments, Duration? timeout]) async {
    windows.events.add('$id:$method');
    Object? result;
    switch (method) {
      case 'player.ready':
        result = {'ready': true};
      case 'player.replaceRequest':
        if (rejectReplace) throw StateError('channel unavailable');
        result = {'ready': true};
      case 'player.prepareClose':
        if (save != null) await save!.future;
        result = {'prepared': true, 'saved': true, 'released': true};
      case 'player.close':
        windows.all.remove(this);
    }
    return result as T?;
  }

  @override
  Future<void> setHandler(Future<Object?> Function(MethodCall) value) async => handler = value;
}

void main() {
  test('shutdown waits for durable preparation before closing the player', () async {
    final windows = FakeWindows();
    final coordinator = PlayerWindowCoordinator(windows);
    await coordinator.openOrReplace(request('first'));
    final player = windows.all.single;
    player.save = Completer<void>();
    final shutdown = coordinator.closeAll();
    await Future<void>.delayed(Duration.zero);
    expect(windows.events.last, '${player.id}:player.prepareClose');
    expect(windows.all, [player]);
    await expectLater(coordinator.openOrReplace(request('blocked')), throwsStateError);
    player.save!.complete();
    await shutdown;
    expect(windows.all, isEmpty);
    expect(windows.created, 1);
  });

  test('queued launch is rejected when exit races native window creation', () async {
    final windows = FakeWindows()..creation = Completer<WindowHandle>();
    final coordinator = PlayerWindowCoordinator(windows);
    final launching = coordinator.openOrReplace(request('first'));
    final launchFailure = expectLater(launching, throwsStateError);
    final queued = coordinator.openOrReplace(request('queued'));
    final queuedFailure = expectLater(queued, throwsStateError);
    await Future<void>.delayed(Duration.zero);
    final shutdown = coordinator.closeAll();
    final latePlayer = FakeWindow(windows, 'late-player', request('first').encode());
    windows.all.add(latePlayer);
    windows.creation!.complete(latePlayer);
    await Future.wait([launchFailure, queuedFailure, shutdown]);
    expect(windows.created, 1);
    expect(windows.events, ['late-player:player.prepareClose', 'late-player:player.close']);
    expect(windows.all, isEmpty);
  });

  test('unavailable replacement retires the old window before creating another', () async {
    final windows = FakeWindows();
    final coordinator = PlayerWindowCoordinator(windows);
    await coordinator.openOrReplace(request('first'));
    windows.all.single.rejectReplace = true;
    await coordinator.openOrReplace(request('second'));
    expect(windows.events, [
      'player-1:player.ready',
      'player-1:player.replaceRequest',
      'player-1:player.prepareClose',
      'player-1:player.close',
      'player-2:player.ready',
    ]);
    expect(windows.all.single.id, 'player-2');
  });

  test('stale close notifications do not invalidate a new active player', () async {
    final windows = FakeWindows();
    final coordinator = PlayerWindowCoordinator(windows);
    final main = FakeWindow(windows, 'main', '');
    var refreshed = 0;
    await coordinator.installMainWindowHandler(main, onPlaybackStateChanged: (_) async => refreshed++);
    await coordinator.openOrReplace(request('first'));
    await main.handler!(const MethodCall('player.closed', {'windowId': 'old-player', 'changedMedia': []}));
    await coordinator.openOrReplace(request('second'));
    expect(windows.created, 1);
    expect(refreshed, 1);
    coordinator.beginShutdown();
    await main.handler!(const MethodCall('player.closed', {'windowId': 'player-1', 'changedMedia': []}));
    expect(refreshed, 1);
  });
}
