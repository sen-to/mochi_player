import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/infrastructure/tmdb/tmdb_search_matcher.dart';

void main() {
  const matcher = TmdbSearchMatcher();

  test('preserves TMDB provider ranking for one complete query', () {
    final first = {'id': 1, 'title': 'Provider result'};
    final later = {'id': 2, 'title': 'Later result'};

    expect(matcher.findBest([first, later], '完整清洗后的中英文标题', isTV: false), same(first));
  });

  test('returns the provider result for shows', () {
    final result = {'id': 3, 'name': '进击的巨人', 'original_name': 'Attack on Titan'};

    expect(matcher.findBest([result], 'Attack on Titan', isTV: true), same(result));
  });
}
