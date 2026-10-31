// 【搜索计划测试】验证完整标题、年份回退与空标题的搜索边界。
// 只测试计划规则；文件名清洗由解析测试覆盖，请求行为由匹配器测试覆盖。

import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/features/library/metadata/domain/scrape_candidate.dart';
import 'package:mochi_player/features/library/metadata/domain/scrape_search_plan.dart';

void main() {
  test('完整中英文标题先带年份搜索，再保留同一标题去掉年份', () {
    const title = '大话西游之仙履奇缘 A Chinese Odyssey Part II Cinderella';
    final attempts = ScrapeSearchPlan.forCandidate(_candidate(title, year: 1995)).attempts;
    expect(attempts.map((attempt) => attempt.query), [title, title]);
    expect(attempts.map((attempt) => attempt.year), [1995, null]);
  });

  test('没有年份时只生成一次搜索，且去掉标题首尾空白', () {
    final attempts = ScrapeSearchPlan.forCandidate(_candidate(' Departures ')).attempts;
    expect(attempts, hasLength(1));
    expect(attempts.single.query, 'Departures');
    expect(attempts.single.year, isNull);
  });

  for (final title in ['', '   ']) {
    test('空标题不发起搜索：${title.isEmpty ? '空字符串' : '仅空白'}', () {
      expect(ScrapeSearchPlan.forCandidate(_candidate(title, year: 2009)).attempts, isEmpty);
    });
  }
}

ScrapeCandidate _candidate(String title, {int? year}) => ScrapeCandidate(
  file: MediaFile(
    id: 0,
    sourceId: 'source',
    path: '/movie.mkv',
    fileName: 'movie.mkv',
    mediaType: MediaType.movie,
    parsedTitle: title,
    parsedYear: year,
    addedAt: DateTime.utc(2026),
  ),
);
