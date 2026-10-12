import 'package:intl/intl.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';

/// Formats media-related values for display.
abstract final class MediaFormat {
  static String fileSize(int bytes, {required String locale}) {
    if (bytes < 0) return '';
    if (bytes == 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var value = bytes.toDouble();
    var suffixIndex = 0;
    while (value >= 1024 && suffixIndex < suffixes.length - 1) {
      value /= 1024;
      suffixIndex++;
    }
    final decimals = suffixIndex == 0
        ? 0
        : suffixIndex >= 3
        ? 2
        : 1;
    return '${NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: decimals).format(value)} ${suffixes[suffixIndex]}';
  }

  static String clockDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  static String? episodeCode(MediaFile file) {
    final season = file.parsedSeason;
    final episode = file.parsedEpisode;
    if (season == null || episode == null) return null;
    return 'S${season.toString().padLeft(2, '0')}E${episode.toString().padLeft(2, '0')}';
  }
}
