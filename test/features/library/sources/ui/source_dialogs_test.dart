// 【来源弹窗回归】验证输入校验、凭据加载失败和关闭后的异步结果隔离。
// 使用来源仓库及协议替身，保存和测试连接仍经过正式来源服务。

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/domain/storage/storage_adapter_registry.dart';
import 'package:mochi_player/core/domain/storage/storage_source_repository.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/library/sources/application/storage_sources_service.dart';
import 'package:mochi_player/features/library/sources/ui/local_source_dialog.dart';
import 'package:mochi_player/features/library/sources/ui/smb_source_dialog.dart';
import 'package:mochi_player/features/library/sources/ui/webdav_source_dialog.dart';
import 'package:mochi_player/l10n/l10n.dart';
import 'package:provider/provider.dart';

void main() {
  late _SourceRepository repository;
  late _Adapter adapter;
  late _Adapter webDavAdapter;
  late StorageSourcesService sources;
  late AppLocalizations strings;
  var saved = 0;

  setUp(() async {
    repository = _SourceRepository();
    adapter = _Adapter();
    webDavAdapter = _Adapter(type: StorageSourceType.webDav);
    sources = StorageSourcesService(
      repository: repository,
      registry: StorageAdapterRegistry([adapter, webDavAdapter]),
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
    await openEditor(tester, (context) => showSmbSourceDialog(context, onSaved: onSaved));
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
    await openEditor(tester, (context) => showWebDavSourceDialog(context, onSaved: onSaved));
    await fill(tester, strings.host, 'nas.local');
    await fill(tester, strings.port, '0');
    await tester.tap(find.widgetWithText(AppButton, strings.testConnection));
    await tester.pumpAndSettle();
    expect(find.text(strings.portRangeError), findsOneWidget);
    expect(webDavAdapter.connectedSource, isNull);
    await tester.tap(find.widgetWithText(AppButton, strings.add));
    await tester.pumpAndSettle();
    expect(find.text(strings.portRangeError), findsOneWidget);
    expect(repository.items, isEmpty);
    expect(saved, 0);
    await fill(tester, strings.port, '5244');
    await tester.tap(find.widgetWithText(AppButton, strings.testConnection));
    await tester.pumpAndSettle();
    expect(webDavAdapter.connectedSource!.endpoint, 'http://nas.local:5244/');
    await tester.tap(find.widgetWithText(AppButton, strings.add));
    await tester.pumpAndSettle();
    final source = repository.items.values.single;
    expect(source.type, StorageSourceType.webDav);
    expect(source.endpoint, 'http://nas.local:5244/');
    expect(saved, 1);
  });

  for (final editor in {'SMB': showSmbSourceDialog, 'WebDAV': showWebDavSourceDialog}.entries) {
    final source = StorageSource(
      id: 'existing',
      name: 'Existing source',
      type: editor.key == 'SMB' ? StorageSourceType.smb : StorageSourceType.webDav,
      endpoint: editor.key == 'SMB' ? 'smb://nas/Media' : 'https://nas/dav',
    );
    testWidgets('${editor.key} 凭据加载失败时提示错误且不打开表单', (tester) async {
      repository.loadCredentials = (_) async => throw StateError('凭据读取失败');
      await openEditor(tester, (context) => editor.value(context, source: source, onSaved: onSaved));
      expect(find.text(strings.sourcesLoadFailed), findsOneWidget);
      expect(find.byType(EditableText), findsNothing);
      expect(tester.takeException(), isNull);
      expect(saved, 0);
    });

    testWidgets('${editor.key} 等待凭据期间页面销毁后不再打开表单', (tester) async {
      final pending = Completer<StorageCredentials?>();
      repository.loadCredentials = (_) => pending.future;
      addTearDown(() {
        if (!pending.isCompleted) pending.complete(null);
      });
      await openEditor(tester, (context) => editor.value(context, source: source, onSaved: onSaved));
      await tester.pumpWidget(const SizedBox.shrink());
      pending.complete(const StorageCredentials(username: 'viewer', password: 'secret'));
      await tester.pumpAndSettle();
      expect(find.byType(EditableText), findsNothing);
      expect(tester.takeException(), isNull);
      expect(saved, 0);
    });
  }

  testWidgets('WebDAV 测试与保存均拒绝无效主机', (tester) async {
    await openEditor(tester, (context) => showWebDavSourceDialog(context, onSaved: onSaved));
    await fill(tester, strings.host, '[');
    await fill(tester, strings.port, '5244');
    for (final action in [strings.testConnection, strings.add]) {
      await tester.tap(find.widgetWithText(AppButton, action));
      await tester.pumpAndSettle();
      expect(find.text(strings.webdavHostInvalid), findsOneWidget);
      expect(adapter.connectedSource, isNull);
      expect(repository.items, isEmpty);
      expect(tester.takeException(), isNull);
    }
    expect(saved, 0);
  });

  testWidgets('cancelling a local editor leaves the source unchanged', (tester) async {
    const source = StorageSource(id: 'local', name: 'Original', type: StorageSourceType.local, endpoint: '/media');
    await repository.save(source);
    await openEditor(tester, (context) => showLocalSourceDialog(context, source: source, onSaved: onSaved));
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
    await openEditor(tester, (context) => showSmbSourceDialog(context, onSaved: onSaved));
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
  Future<StorageCredentials?> Function(String)? loadCredentials;
  @override
  Future<List<StorageSource>> getAll() async => items.values.toList();
  @override
  Future<StorageSource?> getById(String sourceId) async => items[sourceId];
  @override
  Future<StorageCredentials?> readCredentials(String sourceId) async =>
      loadCredentials == null ? credentials[sourceId] : await loadCredentials!(sourceId);
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
  _Adapter({this.type = StorageSourceType.smb});
  final connection = _Connection();
  @override
  final StorageSourceType type;
  StorageSource? connectedSource;
  @override
  Future<StorageConnection> connect(StorageSource source, StorageCredentials? credentials) async {
    connectedSource = source;
    return connection;
  }
}

class _Connection implements StorageConnection {
  Future<List<StorageEntry>>? read;
  int closes = 0;
  @override
  final source = const StorageSource(
    id: 'test',
    name: 'Test',
    type: StorageSourceType.smb,
    endpoint: 'smb://nas/Media',
  );
  @override
  Future<List<StorageEntry>> readDirectory(String path) => read ?? Future.value([]);
  @override
  Future<void> close() async {
    closes++;
  }
}
