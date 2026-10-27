import 'package:mochi_player/features/library/media_file_kind.dart';

/// A filesystem entry used by the file browser.
///
/// This model deliberately contains no library metadata or playback state.
class FileBrowserEntry {
  final String sourceId;
  final String path;
  final String name;
  final MediaFileKind kind;
  final int size;
  final DateTime? modifiedAt;

  const FileBrowserEntry({
    this.sourceId = '',
    required this.path,
    required this.name,
    required this.kind,
    required this.size,
    required this.modifiedAt,
  });

  bool get isDirectory => kind == MediaFileKind.directory;

  bool get isPlayable => kind == MediaFileKind.video;
}
