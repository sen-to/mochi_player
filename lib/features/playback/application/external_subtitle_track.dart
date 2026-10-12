import 'package:mochi_player/features/playback/domain/playback_track.dart';
import 'package:path/path.dart' as path;

/// Creates player tracks for subtitle files chosen outside the media source.
abstract final class ExternalSubtitleTrack {
  /// Produces a stable key for a file selected on the current platform.
  static String normalizePath(String value) => path.normalize(value.trim());

  /// The format is deliberately left to libmpv. Its supported subtitle
  /// demuxers depend on the bundled FFmpeg build and are broader than a fixed
  /// UI extension list.
  static PlaybackSubtitleTrack fromPath(String value) {
    final path = normalizePath(value);
    if (path.isEmpty || path == '.') {
      throw ArgumentError.value(value, 'path', '字幕文件路径不能为空');
    }

    final fileName = path.split(RegExp(r'[/\\]')).last;
    final extension = _extension(fileName);
    final title = extension.isEmpty ? fileName : fileName.substring(0, fileName.length - extension.length - 1);
    return PlaybackSubtitleTrack.externalFile(path, title: title);
  }

  static String _extension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return '';
    return path.substring(dot + 1).toLowerCase();
  }
}
