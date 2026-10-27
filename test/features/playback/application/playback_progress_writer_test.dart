// 【行为测试】验证按请求顺序串行保存播放进度。
// 测试对象的职责边界：避免周期保存、跳转和关闭快照互相覆盖。

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/features/playback/application/playback_progress_writer.dart';

void main() {
  final file = MediaFile(
    id: 1,
    path: '/media/episode.mkv',
    fileName: 'episode.mkv',
    parsedTitle: 'Episode',
    addedAt: DateTime(2026),
  );

  test('writes progress snapshots in the order they were requested', () async {
    final firstWrite = Completer<void>();
    final persistedPositions = <int>[];
    var calls = 0;
    final writer = PlaybackProgressWriter((_, position, {duration}) async {
      calls++;
      persistedPositions.add(position);
      if (calls == 1) await firstWrite.future;
    });

    final first = writer.save(file, 1000, duration: 10000);
    final second = writer.save(file, 9000, duration: 10000);
    await Future<void>.delayed(Duration.zero);

    expect(persistedPositions, [1000]);
    firstWrite.complete();
    await Future.wait([first, second]);
    expect(persistedPositions, [1000, 9000]);
  });

  test('continues with later saves when a write fails', () async {
    final persistedPositions = <int>[];
    final writer = PlaybackProgressWriter((_, position, {duration}) async {
      if (position == 1000) throw StateError('temporary database error');
      persistedPositions.add(position);
    });

    await expectLater(writer.save(file, 1000), throwsStateError);
    await writer.save(file, 2000);

    expect(persistedPositions, [2000]);
  });
}
