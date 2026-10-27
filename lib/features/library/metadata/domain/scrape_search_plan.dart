// 【搜索计划模型】描述一次候选匹配的有序搜索参数。
// 标题和年份决定搜索顺序；实际请求由 MetadataMatcher 执行。

import 'package:mochi_player/features/library/metadata/domain/scrape_candidate.dart';

class ScrapeSearchPlan {
  const ScrapeSearchPlan(this.attempts);

  /// 只使用完整标题；有年份时最多补一次不带年份的搜索。
  factory ScrapeSearchPlan.forCandidate(ScrapeCandidate candidate) {
    final query = candidate.title.trim();
    if (query.isEmpty) return const ScrapeSearchPlan([]);
    return ScrapeSearchPlan([
      ScrapeSearchAttempt(query: query, year: candidate.year),
      if (candidate.year != null) ScrapeSearchAttempt(query: query),
    ]);
  }

  final List<ScrapeSearchAttempt> attempts;
}

class ScrapeSearchAttempt {
  const ScrapeSearchAttempt({required this.query, this.year});

  final String query;
  final int? year;
}
