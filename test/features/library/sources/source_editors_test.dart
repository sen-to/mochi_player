import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/infrastructure/storage/storage_adapter_registry.dart';
import 'package:mochi_player/core/infrastructure/storage/storage_source_repository.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/library/sources/local_source_editor.dart';
import 'package:mochi_player/features/library/sources/smb_source_editor.dart';
import 'package:mochi_player/features/library/sources/storage_sources_service.dart';
import 'package:mochi_player/features/library/sources/webdav_source_editor.dart';
import 'package:mochi_player/l10n/l10n.dart';
import 'package:provider/provider.dart';

void main() {
  late _SourceRepository repository;
  late _Adapter adapter;
  late StorageSourcesService sources;
  late AppLocalizations strings;
  var saved = 0;

  setUp(() async {
    repository = _SourceRepository();
    adapter = _Adapter();
    sources = StorageSourcesService(
      repository: repository,
      registry: StorageAdapterRegistry([adapter]),
      onSourceChanged: (_) => false,
    );
    strings = await AppLocalizations.delegate.load(const Locale('zh'));
    saved = 0;
  });
  tearDown(() async {
    sources.beginShutdown();
    await sources.drain();
  });

  Future<void> onSaved() async {
    saved++;
  }

  Future<void> openEditor(WidgetTester tester, Future<void> Function(BuildContext) open) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      Provider<StorageSourcesService>.value(
        value: sources,
        child: MaterialApp(
          locale: const Locale('zh'),
          theme: AppTheme.darkTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AppMessageHost(
            child: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(onPressed: () => open(context), child: const Text('Open')),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester, String label, String value) => tester.enterText(
    find.descendant(
      of: find.byWidgetPredicate((widget) => widget is AppFormItem && widget.label == label),
      matching: find.byType(EditableText),
    ),
    value,
  );

  testWidgets('SMB editor saves the source and credentials then notifies its owner', (tester) async {
    await openEditor(tester, (context) => showSmbSourceEditor(context, onSaved: onSaved));
    await fill(tester, strings.host, 'nas.local');
    await fill(tester, strings.shareName, 'Media');
    await fill(tester, strings.sharePath, '/Movies');
    await fill(tester, strings.username, 'viewer');
    await fill(tester, strings.password, 'password');
    await tester.tap(find.widgetWithText(AppButton, strings.add));
    await tester.pumpAndSettle();
    final source = repository.items.values.single;
    expect(source.type, StorageSourceType.smb);
    expect(source.endpoint, 'smb://nas.local/Media');
    expect(source.rootPath, '/Movies');
    expect(repository.credentials[source.id]!.username, 'viewer');
    expect(repository.credentials[source.id]!.password, 'password');
    expect(saved, 1);
  });

  testWidgets('WebDAV editor validates the port and saves an empty path as root', (tester) async {
    await openEditor(tester, (context) => showWebDavSourceEditor(context, onSaved: onSaved));
    await fill(tester, strings.host, 'nas.local');
    await fill(tester, strings.port, '0');
    await tester.tap(find.widgetWithText(AppButton, strings.add));
    await tester.pumpAndSettle();
    expect(find.text(strings.portRangeError), findsOneWidget);
    expect(repository.items, isEmpty);
    expect(saved, 0);
    await fill(tester, strings.port, '5244');
    await tester.tap(find.widgetWithText(AppButton, strings.add));
    await tester.pumpAndSettle();
    final source = repository.items.values.single;
    expect(source.type, StorageSourceType.webDav);
    expect(source.endpoint, 'http://nas.local:5244/');
    expect(saved, 1);
  });

  testWidgets('cancelling a local editor leaves the source unchanged', (tester) async {
    const source = StorageSource(id: 'local', name: 'Original', type: StorageSourceType.local, endpoint: '/media');
    await repository.save(source);
    await openEditor(tester, (context) => showLocalSourceEditor(context, source: source, onSaved: onSaved));
    await fill(tester, strings.name, 'Changed');
    await tester.tap(find.widgetWithText(AppButton, strings.cancel));
    await tester.pumpAndSettle();
    expect(repository.items['local'], same(source));
    expect(saved, 0);
  });

  testWidgets('connection tests finishing after dismissal close the connection without updating the modal', (
    tester,
  ) async {
    final read = Completer<List<StorageEntry>>();
    adapter.connection.read = read.future;
    addTearDown(() {
      if (!read.isCompleted) read.complete([]);
    });
    await openEditor(tester, (context) => showSmbSourceEditor(context, onSaved: onSaved));
    await fill(tester, strings.host, 'nas.local');
    await fill(tester, strings.shareName, 'Media');
    await tester.tap(find.widgetWithText(AppButton, strings.testConnection));
    await tester.pump();
    await tester.tap(find.widgetWithText(AppButton, strings.cancel));
    await tester.pumpAndSettle();
    read.complete([]);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(adapter.connection.closes, 1);
    expect(saved, 0);
  });
}

class _SourceRepository implements StorageSourceRepository {
  final items = <String, StorageSource>{};
  final credentials = <String, StorageCredentials>{};
  @override
  Future<List<StorageSource>> getAll() async => items.values.toList();
  @override
  Future<StorageSource?> getById(String sourceId) async => items[sourceId];
  @override
  Future<StorageCredentials?> readCredentials(String sourceId) async => credentials[sourceId];
  @override
  Future<void> save(StorageSource source, {StorageCredentials? credentials}) async {
    items[source.id] = source;
    if (credentials != null) this.credentials[source.id] = credentials;
  }

  @override
  Future<bool> delete(String sourceId) async {
    credentials.remove(sourceId);
    return items.remove(sourceId) != null;
  }

  @override
  Future<int?> deleteWithMedia(String sourceId) async => await delete(sourceId) ? 0 : null;
}

class _Adapter implements StorageAdapter {
  final connection = _Connection();
  @override
  StorageSourceType get type => StorageSourceType.smb;
  @override
  Future<StorageConnection> connect(StorageSource source, StorageCredentials? credentials) async => connection;
}

class _Connection implements StorageConnection {
  Future<List<StorageEntry>> read = Future.value([]);
  int closes = 0;
  @override
  final source = const StorageSource(
    id: 'test',
    name: 'Test',
    type: StorageSourceType.smb,
    endpoint: 'smb://nas/Media',
  );
  @override
  Future<List<StorageEntry>> readDirectory(String path) => read;
  @override
  Future<bool> testConnection() async => true;
  @override
  Future<void> close() async {
    closes++;
  }
}
