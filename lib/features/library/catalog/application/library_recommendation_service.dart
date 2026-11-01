// 【每日推荐用例】订阅目录快照并调用内容推荐算法，发布最多五项的首页推荐。
// 每个订阅拥有数据库监听及跨日计时器，取消订阅时释放；同日仅标题增删触发重新排序。

import 'dart:async';

import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/features/library/catalog/application/library_catalog_repository.dart';
import 'package:mochi_player/features/library/catalog/domain/library_recommendation.dart';
import 'package:mochi_player/features/library/catalog/domain/library_recommendation_candidate.dart';

class LibraryRecommendationService {
  LibraryRecommendationService({required LibraryCatalogRepository repository, DateTime Function()? now})
    : _repository = repository,
      _now = now ?? DateTime.now;

  final LibraryCatalogRepository _repository;
  final DateTime Function() _now;

  Stream<List<LibraryItem>> watch() {
    late StreamController<List<LibraryItem>> controller;
    StreamSubscription<List<LibraryRecommendationCandidate>>? subscription;
    Timer? timer;
    List<LibraryRecommendationCandidate>? snapshot;
    List<LibraryItem> selected = const [];
    Set<String> identities = {};
    DateTime? selectedDay;

    void publish() {
      final candidates = snapshot;
      if (candidates == null) return;
      final now = _now();
      final day = DateTime(now.year, now.month, now.day);
      final byId = {for (final candidate in candidates) candidate.identity: candidate};
      if (selectedDay != day || identities.length != byId.length || !identities.containsAll(byId.keys)) {
        selected = const LibraryRecommendation().select(candidates, day: day);
        selectedDay = day;
        identities = byId.keys.toSet();
      } else {
        // 元数据更新仍发布最新对象；观看进度、收藏变化不让正在浏览的横幅跳动。
        selected = [for (final item in selected) byId['${item is Movie ? 'movie' : 'show'}:${item.tmdbId}']!.item];
      }
      controller.add(List.unmodifiable(selected));
    }

    void scheduleDayChange() {
      final now = _now();
      timer = Timer(DateTime(now.year, now.month, now.day + 1).difference(now), () {
        publish();
        scheduleDayChange();
      });
    }

    controller = StreamController<List<LibraryItem>>(
      onListen: () {
        scheduleDayChange();
        try {
          subscription = _repository.watchRecommendationCandidates().listen(
            (value) {
              snapshot = value;
              publish();
            },
            onError: (Object error, StackTrace stack) {
              // 查询失败后不在跨日计时器中把旧快照当成恢复结果。
              snapshot = null;
              controller.addError(error, stack);
            },
            onDone: () {
              timer?.cancel();
              unawaited(controller.close());
            },
          );
        } catch (error, stack) {
          timer?.cancel();
          controller.addError(error, stack);
          unawaited(controller.close());
        }
      },
      onCancel: () {
        timer?.cancel();
        return subscription?.cancel();
      },
    );
    return controller.stream;
  }
}
