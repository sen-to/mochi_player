// Runs the production media_kit backend over the SMB HTTP bridge using a
// generated file reader. No NAS credentials or user database are accessed.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mochi_player/app/bootstrap/mochi_widgets_binding.dart';
import 'package:mochi_player/core/domain/playback/playback_target.dart';
import 'package:mochi_player/core/infrastructure/storage/smb_http_playback_proxy.dart';
import 'package:mochi_player/core/infrastructure/storage/smb_media_reader.dart';
import 'package:mochi_player/core/platform/desktop_window_service.dart';
import 'package:mochi_player/core/platform/window_service.dart';
import 'package:mochi_player/features/playback/application/playback_engine.dart';
import 'package:mochi_player/features/playback/infrastructure/media_kit_playback_engine.dart';

// ignore: always_use_package_imports
import 'video_fixture.dart';

Future<void> waitFor(bool Function() predicate, String message) async {
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline)) throw TimeoutException(message);
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

void main() async {
  MochiWidgetsBinding();
  MediaKitPlaybackEngine.initialize();
  final directory = await Directory.systemTemp.createTemp('mochi_smb_http_smoke_');
  final fixture = await createVideoFixture(directory, frames: 400);
  final reader = _FixtureReader(await fixture.readAsBytes());
  final proxy = await SmbHttpPlaybackProxy.start(reader);
  final target = PlaybackTarget(url: proxy.uri.toString(), resource: proxy);
  final engine = MediaKitPlaybackEngine(
    const PlaybackOptions(
      cacheMaxBytes: 2 * 1024 * 1024,
      readaheadSeconds: 1,
      hardwareAcceleration: false,
      subtitleLanguagePriority: 'en',
    ),
  );
  final errors = <String>[];
  final errorsSubscription = engine.stream.error.listen(errors.add);
  final host = DesktopWindowHost();
  host.create(
    setup: const WindowSetup(size: Size(720, 405), minimumSize: Size(420, 260)),
    builder: (_) => MaterialApp(home: Scaffold(body: engine.buildVideoSurface())),
  );
  runWidget(host.buildRoot());
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => unawaited(() async {
      var succeeded = false;
      try {
        await engine.open(target);
        await waitFor(
          () => engine.state.duration.inSeconds >= 9 && engine.state.position.inMilliseconds > 300,
          'HTTP video did not start',
        );
        await engine.pause();
        await engine.seek(const Duration(seconds: 6));
        await waitFor(() => engine.state.position.inSeconds >= 5, 'Forward seek failed');
        await engine.seek(const Duration(seconds: 2));
        await waitFor(() => engine.state.position.inSeconds <= 3, 'Backward seek failed');
        for (var round = 0; round < 3; round++) {
          final seeks = <Future<void>>[];
          for (final second in [30, 3, 25, 8, 33, 5, 20, 2]) {
            seeks.add(engine.seek(Duration(seconds: second)));
            await Future<void>.delayed(const Duration(milliseconds: 15));
          }
          await Future.wait(seeks);
          await waitFor(
            () => (engine.state.position.inMilliseconds - 2000).abs() < 700,
            'Rapid seeks did not settle on the last target',
          );
          await engine.seek(const Duration(seconds: 18));
          await waitFor(
            () => (engine.state.position.inMilliseconds - 18000).abs() < 700,
            'Seeking stopped working after rapid seeks',
          );
        }
        debugPrint('SMB HTTP RAPID SEEK PASS');
        if (errors.isNotEmpty) throw StateError(errors.join('\n'));
        if (reader.reads == 0) throw StateError('HTTP bridge did not read the source');
        succeeded = true;
      } catch (error, stack) {
        debugPrint('SMB HTTP SMOKE FAILED: $error\n$stack');
      } finally {
        try {
          await engine.dispose();
          await target.release();
          await target.release();
          await errorsSubscription.cancel();
          if (reader.closeCalls != 1) throw StateError('Source not released exactly once');
          await directory.delete(recursive: true);
        } catch (error) {
          succeeded = false;
          debugPrint('SMB HTTP cleanup failed: $error');
        }
        debugPrint(succeeded ? 'SMB HTTP PLAYBACK SMOKE COMPLETE' : 'SMB HTTP PLAYBACK SMOKE FAILED');
        exit(succeeded ? 0 : 1);
      }
    }()),
  );
}

class _FixtureReader implements SmbMediaReader {
  _FixtureReader(this.bytes);
  final Uint8List bytes;
  int reads = 0;
  int closeCalls = 0;
  @override
  int get length => bytes.length;
  @override
  Future<Uint8List> read(int offset, int length, {bool Function()? isCancelled}) async {
    if (isCancelled?.call() ?? false) throw const SmbReadCancelled();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    if (isCancelled?.call() ?? false) throw const SmbReadCancelled();
    reads++;
    return Uint8List.sublistView(bytes, offset, offset + length);
  }

  @override
  Future<void> close() async => closeCalls++;
}
