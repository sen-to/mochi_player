// 【浏览页面回归】验证来源选择、返回及外部失效均读取 Provider 的唯一选择状态。
// 使用存储替身；页面不持有连接，测试结束先卸载界面再释放 Provider。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/domain/storage/storage_adapter_registry.dart';
import 'package:mochi_player/core/domain/storage/storage_source_repository.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/library/browser/application/file_browser_provider.dart';
import 'package:mochi_player/features/library/browser/ui/file_browser_page.dart';
import 'package:mochi_player/features/library/browser/ui/file_browser_toolbar.dart';
import 'package:mochi_player/features/library/sources/application/storage_sources_service.dart';
import 'package:mochi_player/l10n/l10n.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('选择来源、返回和外部失效不会留下重复的页面选择状态', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final registry = StorageAdapterRegistry([_Adapter()]);
    final browser = FileBrowserProvider(storageAdapterRegistry: registry, readCredentials: (_) async => null);
    final sources = StorageSourcesService(
      repository: _Repository(),
      registry: registry,
      onSourceChanged: browser.invalidateSource,
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      sources.beginShutdown();
      await sources.drain();
      await browser.shutdown();
      browser.dispose();
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<StorageSourcesService>.value(value: sources),
          ChangeNotifierProvider<FileBrowserProvider>.value(value: browser),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          theme: AppTheme.darkTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AppMessageHost(child: FileBrowserPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<FileBrowserToolbar>(find.byType(FileBrowserToolbar)).showDirectoryControls, isFalse);

    await tester.tap(find.text(_source.name));
    await tester.pumpAndSettle();
    expect(find.text('Movie.mkv'), findsOneWidget);
    expect(tester.widget<FileBrowserToolbar>(find.byType(FileBrowserToolbar)).showDirectoryControls, isTrue);

    // 根目录的返回动作应清除 Provider 选择，页面无需下一帧同步一份本地状态。
    tester.widget<FileBrowserToolbar>(find.byType(FileBrowserToolbar)).onBack();
    await tester.pumpAndSettle();
    expect(browser.hasSelectedStorageSource, isFalse);
    expect(find.text('Movie.mkv'), findsNothing);

    await browser.openStorageSource(_source);
    await tester.pumpAndSettle();
    expect(find.text('Movie.mkv'), findsOneWidget);
    browser.invalidateSource(_source.id);
    await tester.pumpAndSettle();
    expect(find.text('Movie.mkv'), findsNothing);
    expect(tester.widget<FileBrowserToolbar>(find.byType(FileBrowserToolbar)).showDirectoryControls, isFalse);
    expect(tester.takeException(), isNull);
  });
}

const _source = StorageSource(id: 'nas', name: '测试来源', type: StorageSourceType.smb, endpoint: 'smb://nas/Media');

class _Adapter implements StorageAdapter {
  @override
  StorageSourceType get type => StorageSourceType.smb;
  @override
  Future<StorageConnection> connect(StorageSource source, StorageCredentials? credentials) async => _Connection();
}

class _Connection implements StorageConnection {
  @override
  StorageSource get source => _source;
  @override
  Future<List<StorageEntry>> readDirectory(String path) async => const [
    StorageEntry(name: 'Movie.mkv', isDirectory: false, size: 1024, modifiedAt: null),
  ];
  @override
  Future<void> close() async {}
}

class _Repository implements StorageSourceRepository {
  @override
  Future<List<StorageSource>> getAll() async => const [_source];
  @override
  Future<StorageSource?> getById(String sourceId) async => sourceId == _source.id ? _source : null;
  @override
  Future<StorageCredentials?> readCredentials(String sourceId) async => null;
  @override
  Future<void> save(StorageSource source, {StorageCredentials? credentials}) => throw UnimplementedError();
  @override
  Future<bool> delete(String sourceId) => throw UnimplementedError();
  @override
  Future<int?> deleteWithMedia(String sourceId) => throw UnimplementedError();
}
