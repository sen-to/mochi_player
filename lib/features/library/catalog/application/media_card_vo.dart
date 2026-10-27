// 【展示对象 VO】封装卡片所需的标题、海报、评分及文件信息。
// VO 表示 View Object；仓库完成批量投影后交给界面，组件不自行补查元数据。

import 'package:mochi_player/core/domain/media/models.dart';

/// 渲染媒体卡片所需的完整展示数据；界面直接消费，不在构建过程中补查元数据。
class MediaCardVO {
  final MediaFile file;
  final LibraryItem? libraryItem;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final double rating;
  final String? playbackContextTitle;

  const MediaCardVO({
    required this.file,
    required this.title,
    this.libraryItem,
    this.subtitle,
    this.imageUrl,
    this.rating = 0,
    this.playbackContextTitle,
  });
}
