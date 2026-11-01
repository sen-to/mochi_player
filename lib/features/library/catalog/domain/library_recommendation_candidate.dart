// 【推荐输入】保存标题级媒体、收藏和观看信号，供仓库边界与推荐用例共同使用。
// 不执行映射或查询，不接管数据库、订阅和计时器。

import 'package:mochi_player/core/domain/media/models.dart';

/// 一个有文件关联的电影或剧集；多版本与多集的信号在数据边界按标题合并。
class LibraryRecommendationCandidate {
  const LibraryRecommendationCandidate({
    required this.item,
    required this.addedAt,
    this.isFavorite = false,
    this.hasStarted = false,
    this.hasCompleted = false,
    this.lastWatchedAt,
  });

  final LibraryItem item;
  final DateTime addedAt;
  final bool isFavorite;
  final bool hasStarted;
  // 剧集表示至少看完一集，用作弱偏好信号，不表示整剧看完。
  final bool hasCompleted;
  final DateTime? lastWatchedAt;

  String get identity => '${item is Movie ? 'movie' : 'show'}:${item.tmdbId}';
}
