import 'package:mochi_player/core/infrastructure/database/entities/entities.dart';
import 'package:mochi_player/features/library/application/scrape_candidate.dart';
import 'package:mochi_player/features/library/application/scrape_plan.dart';
import 'package:mochi_player/features/library/infrastructure/filename_parser.dart';

void main() {
  _usesOneCompleteCleanedTitleWithYearThenWithoutYear();
  _doesNotRetryWithoutYearWhenNoYearWasParsed();
  _keepsMoonAndItsYearInTheFirstSearchAttempt();
}

void _usesOneCompleteCleanedTitleWithYearThenWithoutYear() {
  final plan = const ScrapePlanFactory().createTitleSearchPlan(
    ScrapeCandidate.fromMediaFile(
      MediaFileEntity()
        ..mediaType = StoredMediaType.movie
        ..parsedTitle = '大话西游之仙履奇缘 A Chinese Odyssey Part II Cinderella'
        ..parsedYear = 1995,
    ),
  );

  _expectEquals(plan.attempts.length, 2, 'attempt count');
  _expectEquals(plan.attempts.first.query, '大话西游之仙履奇缘 A Chinese Odyssey Part II Cinderella', 'cleaned complete title');
  _expectEquals(plan.attempts.first.year, 1995, 'first attempt year');
  _expectEquals(plan.attempts.last.query, plan.attempts.first.query, 'fallback title');
  _expectEquals(plan.attempts.last.year, null, 'fallback year');
}

void _doesNotRetryWithoutYearWhenNoYearWasParsed() {
  final plan = const ScrapePlanFactory().createTitleSearchPlan(
    ScrapeCandidate.fromMediaFile(
      MediaFileEntity()
        ..mediaType = StoredMediaType.movie
        ..parsedTitle = 'Departures',
    ),
  );

  _expectEquals(plan.attempts.length, 1, 'attempt count without year');
  _expectEquals(plan.attempts.single.year, null, 'year without parsed value');
}

void _keepsMoonAndItsYearInTheFirstSearchAttempt() {
  final parsed = FilenameParser.parse(fileName: 'Top231.月球.Moon.2009.Bluray.1080p.x265.AAC(5.1).GREENOTEA.mkv');
  final plan = const ScrapePlanFactory().createTitleSearchPlan(
    ScrapeCandidate.fromMediaFile(
      MediaFileEntity()
        ..mediaType = StoredMediaType.movie
        ..parsedTitle = parsed.title
        ..parsedYear = parsed.year,
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
