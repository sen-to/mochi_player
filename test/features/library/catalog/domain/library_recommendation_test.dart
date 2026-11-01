// 【推荐算法回归】验证偏好信号、MMR 多样性、冷启动、身份及每日稳定抽样。
// 使用固定日期和纯业务快照，不访问数据库或外部资源。

import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/features/library/catalog/domain/library_recommendation.dart';
import 'package:mochi_player/features/library/catalog/domain/library_recommendation_candidate.dart';

final _day = DateTime(2026, 11, 1);
const _algorithm = LibraryRecommendation();

LibraryRecommendationCandidate candidate(
  String id, {
  List<String> genres = const [],
  bool favorite = false,
  bool completed = false,
  bool started = false,
  DateTime? watched,
  DateTime? added,
}) => LibraryRecommendationCandidate(
  item: Movie(tmdbId: id, title: id, genres: genres),
  addedAt: added ?? DateTime(2026, 1, 1),
  isFavorite: favorite,
  hasCompleted: completed,
  hasStarted: started || completed,
  lastWatchedAt: watched,
);

void main() {
  test('收藏偏好使同类型未看影片领先，无需其他用户或观看历史', () {
    final result = _algorithm.select(
      [
        candidate('favorite', genres: ['Drama'], favorite: true, started: true),
        candidate('relevant', genres: ['Drama']),
        candidate('unrelated', genres: ['Comedy']),
      ],
      day: _day,
      limit: 1,
    );
    expect(result.single.tmdbId, 'relevant');
  });

  test('看完信号按时间衰减，近期看完的类型比很早的类型更接近偏好', () {
    final result = _algorithm.select(
      [
        candidate('old-signal', genres: ['Drama'], completed: true, watched: DateTime(2020)),
        candidate('recent-signal', genres: ['Comedy'], completed: true, watched: _day),
        candidate('old-match', genres: ['Drama']),
        candidate('recent-match', genres: ['Comedy']),
      ],
      day: _day,
      limit: 1,
    );
    expect(result.single.tmdbId, 'recent-match');
  });

  test('MMR 在相似候选之间引入不同类型，未看优先于已看', () {
    final result = _algorithm.select(
      [
        candidate('signal', genres: ['Drama', 'Comedy'], favorite: true, completed: true),
        candidate('drama-1', genres: ['Drama']),
        candidate('drama-2', genres: ['Drama']),
        candidate('comedy', genres: ['Comedy']),
      ],
      day: _day,
      limit: 2,
    );
    expect(result.expand((item) => item.genres).toSet(), {'Drama', 'Comedy'});
    expect(result.any((item) => item.tmdbId == 'signal'), isFalse);
  });

  test('冷启动无标签也能填满五项，同日跨实例和输入重排结果稳定，日期变化可探索', () {
    final candidates = [for (var i = 0; i < 30; i++) candidate('$i')];
    List<String> ids(List<LibraryItem> items) => items.map((item) => item.tmdbId).toList();
    final today = ids(_algorithm.select(candidates, day: _day));
    expect(today, hasLength(5));
    expect(ids(const LibraryRecommendation().select(candidates.reversed.toList(), day: _day)), today);
    expect(ids(_algorithm.select(candidates, day: DateTime(2026, 11, 2))), isNot(today));
  });

  test('收藏强于同日看完，空类型不产生非法分数，未来时间可处理', () {
    final result = _algorithm.select(
      [
        candidate('favorite', genres: ['Drama'], favorite: true, started: true),
        candidate('completed', genres: ['Comedy'], completed: true, watched: _day),
        candidate('drama', genres: [' Drama ', 'Drama']),
        candidate('comedy', genres: ['Comedy']),
        candidate('empty', added: DateTime(2027)),
      ],
      day: _day,
      limit: 1,
    );
    expect(result.single.tmdbId, 'drama');
  });

  test('小库补足已看、同 ID 电影剧集分别保留，结果只读且边界明确', () {
    final one = candidate('1', completed: true);
    final show = LibraryRecommendationCandidate(
      item: const TVShow(tmdbId: '1', title: 'Show'),
      addedAt: _day,
    );
    final result = _algorithm.select([one, one, show], day: _day);
    expect(result, hasLength(2));
    expect(result.first, isA<TVShow>());
    expect(() => result.clear(), throwsUnsupportedError);
    expect(_algorithm.select([], day: _day), isEmpty);
    expect(_algorithm.select([one], day: _day, limit: 0), isEmpty);
  });
}
