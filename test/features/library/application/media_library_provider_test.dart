// 【媒体库状态测试】验证失败重试、逐流恢复、只读快照与加载期间退出。
// 使用可控查询流和同步替身，不启动数据库、网络或播放引擎。

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/app_failure.dart';
import 'package:mochi_player/core/domain/media/library_activity.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/features/library/application/media_library_provider.dart';
import 'package:mochi_player/features/library/catalog/application/library_catalog_repository.dart';
import 'package:mochi_player/features/library/catalog/application/media_card_vo.dart';
import 'package:mochi_player/features/library/sync/application/library_sync_service.dart';

void main() {
  late _Repository repository;
  late MediaLibraryProvider provider;
  setUp(() {
    repository = _Repository();
    provider = MediaLibraryProvider(repository: repository, syncService: _Sync());
  });
  tearDown(() async {
    provider.dispose();
    await repository.close();
  });

  test('failed initialization can retry and concurrent loads share one operation', () async {
    repository.failInitialization = true;
    final first = provider.loadFromDatabase();
    expect(identical(first, provider.loadFromDatabase()), true);
    await first;
    expect(provider.error, AppFailure.contentLoad);
    expect(provider.isLoading, false);
    repository.failInitialization = false;
    await provider.loadFromDatabase();
    expect(provider.error, isNull);
    expect(repository.initializations, 2);
    await provider.loadFromDatabase();
    expect(repository.initializations, 2);
    expect(repository.count.hasListener, true);
  });

  test('success clears only the error belonging to its own stream', () async {
    await provider.loadFromDatabase();
    repository.count.addError(StateError('count failed'));
    repository.titles.addError(StateError('titles failed'));
    await _flush();
    expect(provider.error, AppFailure.contentLoad);
    repository.count.add(3);
    await _flush();
    expect(provider.error, AppFailure.contentLoad);
    repository.titles.add([]);
    await _flush();
    expect(provider.error, isNull);
    expect(provider.totalFiles, 3);
  });

  test('explicit retry cancels old subscriptions before opening replacements', () async {
    await provider.loadFromDatabase();
    repository.count.addError(StateError('query failed'));
    await _flush();
    await provider.loadFromDatabase();
    expect(provider.error, isNull);
    expect(repository.initializations, 2);
    expect(repository.countListens, 2);
    expect(repository.countCancels, 1);
    repository.count.add(7);
    await _flush();
    expect(provider.totalFiles, 7);
  });

  test('an error before the first value finishes loading and can recover', () async {
    repository.failFirstCount = true;
    await provider.loadFromDatabase();
    expect(provider.isLoading, false);
    expect(provider.error, AppFailure.contentLoad);
    repository.count.add(4);
    await _flush();
    expect(provider.error, isNull);
    expect(provider.totalFiles, 4);
  });

  test('an empty initial stream reports an error and can be retried', () async {
    repository.emptyCount = true;
    await provider.loadFromDatabase();
    expect(provider.isLoading, false);
    expect(provider.error, AppFailure.contentLoad);
    repository.emptyCount = false;
    await provider.loadFromDatabase();
    expect(provider.error, isNull);
  });

  test('published lists are immutable snapshots independent of repository lists', () async {
    repository.initialTitles.add(const Movie(tmdbId: '1', title: 'Movie'));
    await provider.loadFromDatabase();
    repository.initialTitles.clear();
    expect(provider.recentlyAddedContent, hasLength(1));
    expect(() => provider.recentlyAddedContent.clear(), throwsUnsupportedError);
    expect(() => provider.continueWatchingItems.clear(), throwsUnsupportedError);
  });

  test('shutdown finishes when subscribed streams never provide their first value', () async {
    repository.emitInitial = false;
    final loading = provider.loadFromDatabase();
    await _flush();
    expect(repository.count.hasListener, true);
    var notifications = 0;
    provider.addListener(() => notifications++);
    await provider.shutdown().timeout(const Duration(seconds: 1));
    await loading;
    repository.count.add(9);
    await provider.loadFromDatabase();
    await _flush();
    expect(repository.count.hasListener, false);
    expect(provider.totalFiles, 0);
    expect(repository.initializations, 1);
    expect(notifications, 0);
  });
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

class _Repository implements LibraryCatalogRepository {
  _Repository() {
    count = StreamController<int>.broadcast(
      onListen: () {
        countListens++;
        if (emitInitial)
          scheduleMicrotask(() {
            if (failFirstCount) {
              count.addError(StateError('first count failed'));
            } else {
              count.add(0);
            }
          });
      },
      onCancel: () => countCancels++,
    );
    titles = StreamController<List<LibraryItem>>.broadcast(
      onListen: () {
        if (emitInitial) scheduleMicrotask(() => titles.add(initialTitles));
      },
    );
    cards = StreamController<List<MediaCardVO>>.broadcast(
      onListen: () {
        if (emitInitial) scheduleMicrotask(() => cards.add([]));
      },
    );
    hero = StreamController<LibraryItem?>.broadcast(
      onListen: () {
        if (emitInitial) scheduleMicrotask(() => hero.add(null));
      },
    );
  }
  late final StreamController<int> count;
  late final StreamController<List<LibraryItem>> titles;
  late final StreamController<List<MediaCardVO>> cards;
  late final StreamController<LibraryItem?> hero;
  final initialTitles = <LibraryItem>[];
  bool failInitialization = false;
  bool failFirstCount = false;
  bool emitInitial = true;
  bool emptyCount = false;
  int initializations = 0;
  int countListens = 0;
  int countCancels = 0;

  @override
  Future<void> initialize() async {
    initializations++;
    if (failInitialization) throw StateError('database unavailable');
  }

  @override
  Stream<int> watchFileCount() => emptyCount ? const Stream<int>.empty() : count.stream;
  @override
  Stream<List<LibraryItem>> watchTitles({
    LibraryTitleKind? kind,
    String query = '',
    bool recent = false,
    int limit = 100,
  }) => titles.stream;
  @override
  Stream<List<MediaCardVO>> watchContinueWatching({int limit = 100}) => cards.stream;
  @override
  Stream<LibraryItem?> watchHero() => hero.stream;
  Future<void> close() async => Future.wait([count.close(), titles.close(), cards.close(), hero.close()]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Sync extends ChangeNotifier implements LibrarySyncService {
  @override
  bool get isLoading => false;
  @override
  AppFailure? get error => null;
  @override
  double? get scrapeProgress => null;
  @override
  LibraryActivity? get activity => null;
  @override
  void beginShutdown() {}
  @override
  Future<void> shutdown() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
