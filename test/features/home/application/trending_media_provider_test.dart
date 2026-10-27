import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/media/trending_item.dart';
import 'package:mochi_player/core/infrastructure/tmdb/tmdb_service.dart';
import 'package:mochi_player/features/home/application/trending_media_provider.dart';

void main() {
  late _TrendingService service;
  late TrendingMediaProvider provider;
  setUp(() {
    service = _TrendingService();
    provider = TrendingMediaProvider(tmdbService: service);
  });
  tearDown(() => provider.dispose());

  test('ordinary concurrent callers share the same collection load', () async {
    final first = provider.fetch();
    final second = provider.fetch();
    expect(identical(first, second), true);
    expect(service.requests, hasLength(3));
    service.completeBatch(0, 'first');
    await first;
    expect(provider.movies.single.title, 'first');
    expect(provider.isLoading, false);
  });

  test('configuration refreshes coalesce and discard responses from the previous endpoint', () async {
    final first = provider.fetch();
    final changed = provider.fetch(refresh: true);
    provider.fetch(refresh: true);
    service.completeBatch(0, 'old');
    await Future<void>.delayed(Duration.zero);
    expect(provider.movies, isEmpty);
    expect(service.requests, hasLength(6));
    service.completeBatch(3, 'latest');
    await Future.wait([first, changed]);
    expect(provider.movies.single.title, 'latest');
    expect(provider.tvShows.single.title, 'latest');
    expect(provider.topRated.single.title, 'latest');
  });

  test('failure from an old endpoint does not drop the pending configuration refresh', () async {
    final loading = provider.fetch();
    final refreshing = provider.fetch(refresh: true);
    for (final request in service.requests) {
      request.completeError(StateError('old endpoint unavailable'));
    }
    await Future<void>.delayed(Duration.zero);
    expect(service.requests, hasLength(6));
    service.completeBatch(3, 'recovered');
    await Future.wait([loading, refreshing]);
    expect(provider.movies.single.title, 'recovered');
  });

  test('removing configuration during an active load clears the collections', () async {
    final loading = provider.fetch();
    service.configured = false;
    final cleared = provider.fetch(refresh: true);
    service.completeBatch(0, 'old');
    await Future.wait([loading, cleared]);
    expect(provider.hasContent, false);
    expect(service.requests, hasLength(3));
  });

  test('disposed providers ignore late responses and do not notify listeners', () async {
    final localProvider = TrendingMediaProvider(tmdbService: service);
    var notifications = 0;
    localProvider.addListener(() => notifications++);
    final loading = localProvider.fetch();
    expect(notifications, 1);
    localProvider.dispose();
    service.completeBatch(0, 'late');
    await loading;
    expect(notifications, 1);
    expect(localProvider.hasContent, false);
  });
}

class _TrendingService extends TmdbService {
  bool configured = true;
  final requests = <Completer<List<TrendingItem>>>[];
  @override
  bool get isConfigured => configured;
  Future<List<TrendingItem>> _load() {
    final request = Completer<List<TrendingItem>>();
    requests.add(request);
    return request.future;
  }

  void completeBatch(int start, String title) {
    for (final request in requests.skip(start).take(3)) {
      request.complete([TrendingItem(tmdbId: title, title: title, isMovie: true)]);
    }
  }

  @override
  Future<List<TrendingItem>> fetchTrendingMovies({int limit = 3}) => _load();
  @override
  Future<List<TrendingItem>> fetchTrendingTV({int limit = 3}) => _load();
  @override
  Future<List<TrendingItem>> fetchTopRated({int limit = 3}) => _load();
}
