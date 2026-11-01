// 【推荐规则】以标题级收藏和观看信号构建类型偏好，按相关性与 MMR 多样性选择每日推荐。
// 只消费不可变业务快照和显式日期，不读取数据库、不持有计时器或其他资源。

import 'dart:math' as math;

import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/features/library/catalog/domain/library_recommendation_candidate.dart';

/// 类型采用归一化二值向量，收藏强于看完；观看偏好按 90 天半衰期衰减。
/// 返回最多 limit 个条目；未看优先，数量不足时补充已开始内容，所有结果均按类型及 ID 去重。
class LibraryRecommendation {
  const LibraryRecommendation();

  List<LibraryItem> select(List<LibraryRecommendationCandidate> candidates, {required DateTime day, int limit = 5}) {
    if (limit <= 0) return const [];
    final unique = {for (final candidate in candidates) candidate.identity: candidate};
    final all = unique.values.toList()..sort((a, b) => a.identity.compareTo(b.identity));
    final vectors = {for (final candidate in all) candidate.identity: _vector(candidate.item.genres)};
    final profile = <String, double>{};
    final date = DateTime.utc(day.year, day.month, day.day);
    for (final candidate in all) {
      final watched = candidate.lastWatchedAt;
      final age = watched == null ? 0 : math.max(0, date.difference(watched.toUtc()).inDays);
      final weight =
          (candidate.isFavorite ? 3.0 : 0.0) + (candidate.hasCompleted ? math.pow(0.5, age / 90).toDouble() : 0.0);
      for (final entry in vectors[candidate.identity]!.entries) {
        profile.update(entry.key, (value) => value + entry.value * weight, ifAbsent: () => entry.value * weight);
      }
    }
    _normalize(profile);
    final scores = <String, double>{};
    for (final candidate in all) {
      final age = math.max(0, date.difference(candidate.addedAt.toUtc()).inDays);
      final quality =
          (candidate.item.backdropUrl?.trim().isNotEmpty == true ? 0.7 : 0.0) +
          (candidate.item.overview?.trim().isNotEmpty == true ? 0.3 : 0.0);
      scores[candidate.identity] =
          0.60 * _similarity(profile, vectors[candidate.identity]!) +
          0.15 * math.pow(0.5, age / 30) +
          0.10 * quality +
          0.15 * _dailyNoise(date, candidate.identity);
    }
    final selected = <LibraryRecommendationCandidate>[];
    // 未看内容先填满；库较小时再用已开始的标题补足，不因缺少历史或图片而隐藏横幅。
    for (final started in [false, true]) {
      final remaining = all.where((candidate) => candidate.hasStarted == started).toList();
      while (remaining.isNotEmpty && selected.length < limit) {
        double score(LibraryRecommendationCandidate candidate) {
          final redundancy = selected.fold<double>(
            0,
            (value, chosen) => math.max(value, _similarity(vectors[candidate.identity]!, vectors[chosen.identity]!)),
          );
          return 0.7 * scores[candidate.identity]! - 0.3 * redundancy;
        }

        var bestIndex = 0;
        var bestScore = score(remaining.first);
        for (var index = 1; index < remaining.length; index++) {
          final nextScore = score(remaining[index]);
          if (nextScore > bestScore) {
            bestIndex = index;
            bestScore = nextScore;
          }
        }
        selected.add(remaining.removeAt(bestIndex));
      }
    }
    return List.unmodifiable(selected.map((candidate) => candidate.item));
  }

  Map<String, double> _vector(List<String> genres) {
    final vector = {
      for (final genre in genres)
        if (genre.trim().isNotEmpty) genre.trim().toLowerCase(): 1.0,
    };
    _normalize(vector);
    return vector;
  }

  void _normalize(Map<String, double> vector) {
    final norm = math.sqrt(vector.values.fold<double>(0, (sum, value) => sum + value * value));
    if (norm == 0) return;
    for (final key in vector.keys) {
      vector[key] = vector[key]! / norm;
    }
  }

  double _similarity(Map<String, double> a, Map<String, double> b) =>
      a.entries.fold<double>(0, (sum, entry) => sum + entry.value * (b[entry.key] ?? 0));

  // 显式 31 位哈希，不使用跨进程不保证稳定的 Object.hash / String.hashCode。
  double _dailyNoise(DateTime day, String identity) {
    var hash = 0;
    for (final code in '${day.year}-${day.month}-${day.day}:$identity'.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    // 混合相邻 ID，避免连续编号获得近似分值。
    hash = ((hash ^ (hash >> 16)) * 0x45d9f3b) & 0x7fffffff;
    hash = ((hash ^ (hash >> 16)) * 0x45d9f3b) & 0x7fffffff;
    return (hash ^ (hash >> 16)) / 0x7fffffff;
  }
}
