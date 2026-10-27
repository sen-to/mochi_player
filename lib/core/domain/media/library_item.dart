// 【共享模型】定义电影和剧集共有的标题、图片、评分等能力。
// 供列表、详情与播放前选择使用，不保存界面状态。

import 'package:mochi_player/core/domain/media/artist.dart';

/// 共享媒体界面可展示和打开的媒体库条目。
abstract interface class LibraryItem {
  String get tmdbId;

  String get title;

  String? get originalTitle;

  int? get releaseYear;

  String? get posterUrl;

  String? get backdropUrl;

  String? get logoUrl;

  String? get overview;

  String? get certification;

  double get rating;

  List<String> get genres;

  List<Artist> get cast;
}
