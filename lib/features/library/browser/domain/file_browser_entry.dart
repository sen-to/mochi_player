// 【文件浏览模型】描述条目名称、相对路径、大小、时间与类型。
// 不混入媒体库元数据或播放状态。

import 'package:mochi_player/features/library/domain/media_file_kind.dart';

/// 文件浏览器条目模型，不包含媒体库元数据或播放状态。
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
