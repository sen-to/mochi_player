// 【每日推荐用例回归】验证同日顺序、跨日刷新、元数据替换与监听取消。
// 使用受控目录流及测试时钟，计时器由用例订阅持有并在测试结束取消。

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/features/library/catalog/application/library_catalog_repository.dart';
import 'package:mochi_player/features/library/catalog/application/library_recommendation_service.dart';
import 'package:mochi_player/features/library/catalog/domain/library_recommendation.dart';
import 'package:mochi_player/features/library/catalog/domain/library_recommendation_candidate.dart';

class _Repository implements LibraryCatalogRepository {
  final source = StreamController<List<LibraryRecommendationCandidate>>();

  @override
  Stream<List<LibraryRecommendationCandidate>> watchRecommendationCandidates() => source.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

List<LibraryRecommendationCandidate> _candidates({bool started = false, String title = 'Title'}) => [
  for (var i = 0; i < 20; i++)
    LibraryRecommendationCandidate(
      item: Movie(tmdbId: '$i', title: '$title $i', genres: [i.isEven ? 'Drama' : 'Comedy']),
      addedAt: DateTime(2026),
      hasStarted: started,
    ),
];

void main() {
  test('同日信号变化保留选择，更新元数据，跨日使用最新信号重算，取消释放监听', () {
    fakeAsync((async) {
      var now = DateTime(2026, 11, 1, 23, 59, 59);
      final repository = _Repository();
      final values = <List<LibraryItem>>[];
      final subscription = LibraryRecommendationService(
        repository: repository,
        now: () => now,
      ).watch().listen(values.add);
      repository.source.add(_candidates());
      async.flushMicrotasks();
      final original = values.last.map((item) => item.tmdbId).toList();
      repository.source.add(_candidates(started: true, title: 'Updated'));
      async.flushMicrotasks();
      expect(values.last.map((item) => item.tmdbId), original);
      expect(values.last.every((item) => item.title.startsWith('Updated')), isTrue);
      final next = _candidates(started: true, title: 'Updated');
      now = DateTime(2026, 11, 2);
      async.elapse(const Duration(seconds: 1));
      expect(
        values.last.map((item) => item.tmdbId),
        const LibraryRecommendation().select(next, day: now).map((item) => item.tmdbId),
      );
      repository.source.add([]);
      async.flushMicrotasks();
      expect(values.last, isEmpty);
      unawaited(subscription.cancel());
      async.flushMicrotasks();
      expect(repository.source.hasListener, isFalse);
      expect(async.pendingTimers, isEmpty);
      unawaited(repository.source.close());
      async.flushMicrotasks();
    });
  });

  test('查询错误向调用方报告，恢复后继续发布，空流可结束', () async {
    final repository = _Repository();
    final errors = <Object>[];
    final values = <List<LibraryItem>>[];
    var done = false;
    final subscription = LibraryRecommendationService(
      repository: repository,
    ).watch().listen(values.add, onError: errors.add, onDone: () => done = true);
    repository.source.addError(StateError('unavailable'));
    await Future<void>.delayed(Duration.zero);
    expect(errors, hasLength(1));
    expect(values, isEmpty);
    repository.source.add(_candidates());
    await Future<void>.delayed(Duration.zero);
    expect(values.single, hasLength(5));
    await repository.source.close();
    await Future<void>.delayed(Duration.zero);
    expect(done, isTrue);
    await subscription.cancel();
  });
}
