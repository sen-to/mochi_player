import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/formatters/media_format.dart';
import 'package:mochi_player/l10n/generated/app_localizations_zh.dart';

void main() {
  test('formats file sizes consistently through terabytes', () {
    expect(MediaFormat.fileSize(-1, locale: 'en'), isEmpty);
    expect(MediaFormat.fileSize(0, locale: 'en'), '0 B');
    expect(MediaFormat.fileSize(1023, locale: 'en'), '1,023 B');
    expect(MediaFormat.fileSize(1024, locale: 'en'), '1.0 KB');
    expect(MediaFormat.fileSize(1024 * 1024 * 1024, locale: 'en'), '1.00 GB');
    expect(MediaFormat.fileSize(1024 * 1024 * 1024 * 1024, locale: 'en'), '1.00 TB');
  });

  test('formats clock, episode codes, and localized season counts', () {
    expect(MediaFormat.clockDuration(const Duration(hours: 1, minutes: 2, seconds: 3)), '1:02:03');
    expect(MediaFormat.episodeCode(_episode()), 'S02E07');
    expect(AppLocalizationsZh().totalSeasonCount(1), '共 1 季');
    expect(AppLocalizationsZh().totalSeasonCount(4), '共 4 季');
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
