import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/app_failure.dart';
import 'package:mochi_player/features/library/sync/library_sync_service.dart';
import 'package:mochi_player/features/library/metadata/metadata_matcher.dart';
import 'package:mochi_player/features/library/metadata/metadata_scraper.dart';

import '../../../support/library_sync_fakes.dart';

void main() {
  late FakeLibrarySourceScanner scanner;
  late FakeLibrarySyncRepository repository;
  late FakeMetadataSource metadata;
  late LibrarySyncService sync;

  setUp(() {
    scanner = FakeLibrarySourceScanner();
    repository = FakeLibrarySyncRepository();
    metadata = FakeMetadataSource()..isConfigured = false;
    final metadataRepository = FakeMetadataRepository();
    sync = LibrarySyncService(
      repository: repository,
      sourceScanner: scanner,
      metadataScraper: MetadataScraper(
        repository: metadataRepository,
        matchResolver: MetadataMatcher(source: metadata, repository: metadataRepository),
      ),
    );
  });
  tearDown(() async {
    await sync.shutdown();
    sync.dispose();
  });

  test('complete scans save bounded batches before removing missing files', () async {
    final files = [for (var i = 0; i < 130; i++) libraryFile('/$i')];
    repository.paths['local'] = {'/0', '/missing'};
    final session = FakeLibrarySourceScan()..onScan = () => Stream.fromIterable(files);
    scanner.sessions['local'] = session;
    final summary = (await sync.scanEnabledMediaSources())!;
    expect(repository.batches.map((batch) => batch.length), [128, 2]);
    expect(repository.batches.first.first.path, '/0');
    expect(repository.cleanedSources, ['local']);
    expect(repository.seenPaths['local'], files.map((file) => file.path).toSet());
    expect(summary.discoveredFileCount, 130);
    expect(summary.newFileCount, 129);
    expect(summary.removedFileCount, 1);
    expect(summary.metadataMatchedCount, isNull);
    expect(repository.candidateReadCount, 0);
    expect(session.closeCount, 1);
  });

  test('incomplete scans persist discoveries without deleting old paths', () async {
    final session = FakeLibrarySourceScan()
      ..hadReadError = true
      ..onScan = () => Stream.value(libraryFile('/found'));
    scanner.sessions['local'] = session;
    final summary = (await sync.scanEnabledMediaSources())!;
    expect(repository.batches.single.single.path, '/found');
    expect(repository.cleanedSources, isEmpty);
    expect(summary.completedSourceCount, 0);
    expect(summary.failedSourceCount, 1);
    expect(session.closeCount, 1);
  });

  test('a stream failure flushes successful discoveries and closes the session', () async {
    final session = FakeLibrarySourceScan()
      ..onScan = () async* {
        yield libraryFile('/found');
        throw StateError('directory unavailable');
      };
    scanner.sessions['local'] = session;
    final summary = (await sync.scanEnabledMediaSources())!;
    expect(repository.batches.single.single.path, '/found');
    expect(repository.cleanedSources, isEmpty);
    expect(summary.failedSourceCount, 1);
    expect(session.closeCount, 1);
  });

  test('a failed source does not prevent later sources from scanning', () async {
    scanner.available = [librarySource('failed'), librarySource('healthy')];
    final session = FakeLibrarySourceScan()..onScan = () => Stream.value(libraryFile('/found', sourceId: 'healthy'));
    scanner.onOpen = (source) async {
      if (source.id == 'failed') throw StateError('connection failed');
      return session;
    };
    final summary = (await sync.scanEnabledMediaSources())!;
    expect(scanner.opened, ['failed', 'healthy']);
    expect(summary.completedSourceCount, 1);
    expect(summary.failedSourceCount, 1);
    expect(repository.cleanedSources, ['healthy']);
    expect(session.closeCount, 1);
  });

  test('a failed batch is not implicitly retried during cleanup', () async {
    final session = FakeLibrarySourceScan()
      ..onScan = () => Stream.fromIterable([for (var i = 0; i < 128; i++) libraryFile('/$i')]);
    scanner.sessions['local'] = session;
    var writes = 0;
    repository.onSave = (_) async {
      writes++;
      throw StateError('disk full');
    };
    final summary = (await sync.scanEnabledMediaSources())!;
    expect(writes, 1);
    expect(repository.cleanedSources, isEmpty);
    expect(summary.failedSourceCount, 1);
    expect(session.closeCount, 1);
  });

  test('close failures count the source as failed exactly once', () async {
    repository.paths['local'] = {'/missing'};
    final session = FakeLibrarySourceScan()
      ..onScan = (() => Stream.value(libraryFile('/found')))
      ..onClose = () async => throw StateError('close failed');
    scanner.sessions['local'] = session;
    final summary = (await sync.scanEnabledMediaSources())!;
    expect(summary.completedSourceCount, 0);
    expect(summary.failedSourceCount, 1);
    expect(summary.discoveredFileCount, 1);
    expect(summary.newFileCount, 1);
    expect(summary.removedFileCount, 1);
    expect(repository.batches.single.single.path, '/found');
    expect(session.closeCount, 1);
  });

  test('duplicate requests are rejected even after a state reset', () async {
    final entered = Completer<void>();
    final opened = Completer<FakeLibrarySourceScan>();
    scanner.onOpen = (_) {
      entered.complete();
      return opened.future;
    };
    final task = sync.scanEnabledMediaSources();
    await entered.future;
    sync.reset();
    expect(sync.isLoading, isTrue);
    expect(await sync.scanEnabledMediaSources(), isNull);
    opened.complete(FakeLibrarySourceScan());
    await task;
    expect(scanner.opened, ['local']);
  });

  test('shutdown awaits a late connection and closes it without starting a scan', () async {
    final entered = Completer<void>();
    final opened = Completer<FakeLibrarySourceScan>();
    final session = FakeLibrarySourceScan();
    scanner.onOpen = (_) {
      entered.complete();
      return opened.future;
    };
    final task = sync.scanEnabledMediaSources();
    await entered.future;
    var finished = false;
    final shutdown = sync.shutdown().then((_) => finished = true);
    await Future<void>.delayed(Duration.zero);
    expect(finished, isFalse);
    expect(await sync.scanEnabledMediaSources(), isNull);
    opened.complete(session);
    expect(await task, isNull);
    await shutdown;
    expect(session.closeCount, 1);
    expect(session.scanCount, 0);
    expect(repository.cleanedSources, isEmpty);
  });

  test('shutdown during path lookup closes the session without starting directory reads', () async {
    final entered = Completer<void>();
    final paths = Completer<Set<String>>();
    final session = FakeLibrarySourceScan();
    scanner.sessions['local'] = session;
    repository.onSourcePaths = (_) {
      entered.complete();
      return paths.future;
    };
    final task = sync.scanEnabledMediaSources();
    await entered.future;
    final shutdown = sync.shutdown();
    paths.complete({});
    expect(await task, isNull);
    await shutdown;
    expect(session.scanCount, 0);
    expect(session.closeCount, 1);
    expect(repository.cleanedSources, isEmpty);
  });

  test('shutdown drains an active scan without deleting unseen files or scraping', () async {
    final paused = Completer<void>();
    final release = Completer<void>();
    metadata.isConfigured = true;
    final session = FakeLibrarySourceScan()
      ..onScan = () async* {
        yield libraryFile('/first');
        paused.complete();
        await release.future;
        yield libraryFile('/late');
      };
    scanner.sessions['local'] = session;
    final task = sync.scanEnabledMediaSources();
    await paused.future;
    final shutdown = sync.shutdown();
    release.complete();
    expect(await task, isNull);
    await shutdown;
    expect(repository.batches.single.single.path, '/first');
    expect(repository.cleanedSources, isEmpty);
    expect(repository.candidateReadCount, 0);
    expect(session.closeCount, 1);
    expect(sync.isLoading, isFalse);
  });

  test('no available sources reports an actionable error', () async {
    scanner.available = [];
    expect(await sync.scanEnabledMediaSources(), isNull);
    expect(sync.error, AppFailure.scanSourceRequired);
    expect(scanner.opened, isEmpty);
  });
}
