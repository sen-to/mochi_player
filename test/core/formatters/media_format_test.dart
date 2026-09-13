import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/formatters/media_format.dart';

void main() {
  test('formats file sizes consistently through terabytes', () {
    expect(MediaFormat.fileSize(-1), isEmpty);
    expect(MediaFormat.fileSize(0), '0 B');
    expect(MediaFormat.fileSize(1023), '1023 B');
    expect(MediaFormat.fileSize(1024), '1.0 KB');
    expect(MediaFormat.fileSize(1024 * 1024 * 1024), '1.00 GB');
    expect(MediaFormat.fileSize(1024 * 1024 * 1024 * 1024), '1.00 TB');
  });

  test('formats clock, compact, episode, and season labels', () {
    expect(MediaFormat.clockDuration(const Duration(hours: 1, minutes: 2, seconds: 3)), '1:02:03');
    expect(MediaFormat.compactDuration(const Duration(minutes: 42)), '42m');
    expect(MediaFormat.episodeLabel(_episode()), '第 2 季 第 7 集');
    expect(MediaFormat.seasonCount(1), '1 季');
    expect(MediaFormat.seasonCount(4), '4 季');
  });
}

MediaFile _episode() => MediaFile(
  id: 1,
  path: '/media/item.mkv',
  fileName: 'item.mkv',
  parsedTitle: 'Item',
  parsedSeason: 2,
  parsedEpisode: 7,
  addedAt: DateTime(2026),
);
