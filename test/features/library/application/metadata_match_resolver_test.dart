import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/app_failure.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/features/library/application/metadata_match_resolver.dart';
import 'package:mochi_player/features/library/application/metadata_source.dart';
import 'package:mochi_player/features/library/application/scrape_candidate.dart';

import '../../../support/library_sync_fakes.dart';

void main() {
  late FakeMetadataSource source;
  late FakeMetadataRepository repository;
  late MetadataMatchResolver resolver;
  setUp(() {
    source = FakeMetadataSource();
    repository = FakeMetadataRepository();
    resolver = MetadataMatchResolver(source: source, repository: repository);
  });

  test('an explicit ID selects local metadata before contacting the provider', () async {
    repository.movies['2'] = const Movie(tmdbId: '2', title: 'Correct');
    repository.shows['2'] = const TVShow(tmdbId: '2', title: 'Correct');
    final candidate = ScrapeCandidate.fromMediaFile(
      libraryFile('/movie').copyWith(explicitTmdbId: '2', movieTmdbId: '1', tvShowTmdbId: '1'),
    );
    expect((await resolver.resolveMovie(candidate)).metadata!.tmdbId, '2');
    expect((await resolver.resolveTVShow(candidate)).metadata!.tmdbId, '2');
    expect(source.calls, isEmpty);
  });

  test('known remote ID is used before any title fallback', () async {
    source.movies['2'] = const Movie(tmdbId: '2', title: 'Remote');
    final candidate = ScrapeCandidate.fromMediaFile(libraryFile('/movie').copyWith(explicitTmdbId: '2'));
    final match = await resolver.resolveMovie(candidate);
    expect(match.source, MetadataMatchSource.explicitId);
    expect(match.metadata!.tmdbId, '2');
    expect(source.calls, ['movie:2']);
  });

  test('a successful empty search permits a yearless fallback', () async {
    source.onSearchMovie = (title, year) async => year == null ? const Movie(tmdbId: '3', title: 'Found') : null;
    final candidate = ScrapeCandidate.fromMediaFile(libraryFile('/movie').copyWith(parsedYear: 2020));
    final match = await resolver.resolveMovie(candidate);
    expect(match.metadata!.tmdbId, '3');
    expect(source.calls, ['searchMovie:Example:2020', 'searchMovie:Example:null']);
  });

  test('a request failure propagates without becoming unmatched or triggering fallback', () async {
    const failure = MetadataRequestFailure(userFailure: AppFailure.tmdbTimeout, isRetryable: true);
    source.onSearchMovie = (_, _) async => throw failure;
    final candidate = ScrapeCandidate.fromMediaFile(libraryFile('/movie').copyWith(parsedYear: 2020));
    await expectLater(resolver.resolveMovie(candidate), throwsA(same(failure)));
    expect(source.calls, ['searchMovie:Example:2020']);
    expect(repository.unmatched, isEmpty);
  });
}
