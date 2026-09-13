import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/features/playback/domain/playback_queue.dart';

MediaFile _file(int id, String path) =>
    MediaFile(id: id, path: path, fileName: path.split('/').last, parsedTitle: 'Show', addedAt: DateTime(2026));

void main() {
  test('deduplicates items and selects the requested initial item', () {
    final first = _file(1, '/media/one.mkv');
    final second = _file(2, '/media/two.mkv');
    final queue = PlaybackQueue(initialItem: second, items: [first, second, _file(3, '/media/one.mkv')]);

    expect(queue.current, second);
    expect(queue.hasPrevious, isTrue);
    expect(queue.hasNext, isFalse);
    expect(queue.itemAtOffset(-1), first);
  });

  test('inserts a missing initial item and moves only within bounds', () {
    final initial = _file(1, '/media/initial.mkv');
    final queue = PlaybackQueue(initialItem: initial, items: [_file(2, '/media/next.mkv')]);

    expect(queue.current, initial);
    expect(queue.itemAtOffset(-1), isNull);
    queue.selectOffset(1);
    expect(queue.current.path, '/media/next.mkv');
    expect(() => queue.selectOffset(1), throwsRangeError);
  });
}
