// 【推荐数据映射】把 SQL 标题聚合行与已映射的媒体模型转换为推荐输入。
// 仅转换边界字段，不执行查询、不持有数据库或订阅。

import 'package:drift/drift.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/features/library/catalog/domain/library_recommendation_candidate.dart';

class LibraryRecommendationMapper {
  static LibraryRecommendationCandidate fromRow(QueryRow row, LibraryItem item) => LibraryRecommendationCandidate(
    item: item,
    addedAt: row.read<DateTime>('added_at'),
    isFavorite: row.read<int>('favorite') != 0,
    hasStarted: row.read<int>('started') != 0,
    hasCompleted: row.read<int>('completed') != 0,
    lastWatchedAt: row.readNullable<DateTime>('watched_at'),
  );
}
