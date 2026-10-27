// 【行为测试】验证按显式 ID、已有 ID、标题与年份选择元数据。
// 测试对象的职责边界：候选与搜索规则由 domain 提供；请求失败不等同于未匹配。

import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/features/library/metadata/application/scrape_candidate_mapper.dart';
import 'package:mochi_player/features/library/metadata/domain/scrape_search_plan.dart';
import 'package:mochi_player/features/library/sync/domain/media_filename_parser.dart';

void main() {
  _usesOneCompleteCleanedTitleWithYearThenWithoutYear();
  _doesNotRetryWithoutYearWhenNoYearWasParsed();
  _keepsMoonAndItsYearInTheFirstSearchAttempt();
}

void _usesOneCompleteCleanedTitleWithYearThenWithoutYear() {
  final plan = ScrapeSearchPlan.forCandidate(
    ScrapeCandidateMapper.fromMediaFile(
      MediaFile(
        mediaType: MediaType.movie,
        parsedTitle: '大话西游之仙履奇缘 A Chinese Odyssey Part II Cinderella',
        parsedYear: 1995,
        id: 0,
        sourceId: '',
        path: '',
        fileName: '',
        addedAt: DateTime.now(),
      ),
    ),
  );

  _expectEquals(plan.attempts.length, 2, 'attempt count');
  _expectEquals(plan.attempts.first.query, '大话西游之仙履奇缘 A Chinese Odyssey Part II Cinderella', 'cleaned complete title');
  _expectEquals(plan.attempts.first.year, 1995, 'first attempt year');
  _expectEquals(plan.attempts.last.query, plan.attempts.first.query, 'fallback title');
  _expectEquals(plan.attempts.last.year, null, 'fallback year');
}

void _doesNotRetryWithoutYearWhenNoYearWasParsed() {
  final plan = ScrapeSearchPlan.forCandidate(
    ScrapeCandidateMapper.fromMediaFile(
      MediaFile(
        mediaType: MediaType.movie,
        parsedTitle: 'Departures',
        id: 0,
        sourceId: '',
        path: '',
        fileName: '',
        addedAt: DateTime.now(),
      ),
    ),
  );

  _expectEquals(plan.attempts.length, 1, 'attempt count without year');
  _expectEquals(plan.attempts.single.year, null, 'year without parsed value');
}

void _keepsMoonAndItsYearInTheFirstSearchAttempt() {
  final parsed = MediaFilenameParser.parse(fileName: 'Top231.月球.Moon.2009.Bluray.1080p.x265.AAC(5.1).GREENOTEA.mkv');
  final plan = ScrapeSearchPlan.forCandidate(
    ScrapeCandidateMapper.fromMediaFile(
      MediaFile(
        mediaType: MediaType.movie,
        parsedTitle: parsed.title,
        parsedYear: parsed.year,
        id: 0,
        sourceId: '',
        path: '',
        fileName: '',
        addedAt: DateTime.now(),
      ),
    ),
  );

  _expectEquals(parsed.title, '月球 Moon', 'parsed Moon title');
  _expectEquals(parsed.year, 2009, 'parsed Moon year');
  _expectEquals(plan.attempts.first.query, '月球 Moon', 'Moon search title');
  _expectEquals(plan.attempts.first.year, 2009, 'Moon search year');
}

void _expectEquals(Object? actual, Object? expected, String label) {
  if (actual == expected) return;
  throw StateError('Unexpected $label: expected $expected, got $actual.');
}
