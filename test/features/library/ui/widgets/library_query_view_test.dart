// 【行为测试】验证维护稳定的数据流订阅，并在滚动时扩展有限查询范围。
// 测试对象的职责边界：查询由媒体库 Provider 发起，组件不直接访问数据库。

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/app/bootstrap/application_dependencies.dart';
import 'package:mochi_player/core/data/database/app_database.dart';
import 'package:mochi_player/core/data/database/sqlite_setup.dart';
import 'package:mochi_player/core/data/storage/local_storage_adapter.dart';
import 'package:mochi_player/core/data/storage/smb_storage_adapter.dart';
import 'package:mochi_player/core/data/storage/webdav_storage_adapter.dart';
import 'package:mochi_player/core/data/tmdb/tmdb_api.dart';
import 'package:mochi_player/core/domain/storage/storage_adapter_registry.dart';
import 'package:mochi_player/features/library/application/media_library_provider.dart';
import 'package:mochi_player/features/library/ui/widgets/library_query_view.dart';
import 'package:mochi_player/features/settings/data/app_settings_repository_impl.dart';
import 'package:mochi_player/l10n/l10n.dart';
import 'package:provider/provider.dart';

void main() {
  late AppDatabase db;
  late MediaLibraryProvider provider;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory(setup: configureSqlite));
    await db.init();
    provider = ApplicationDependencies(
      database: db,
      tmdb: TmdbApi(),
      storageRegistry: StorageAdapterRegistry([LocalStorageAdapter(), WebDavStorageAdapter(), SmbStorageAdapter()]),
      settingsRepository: AppSettingsRepositoryImpl(),
    ).mediaLibrary;
  });
  tearDown(() async {
    provider.dispose();
    await db.close();
  });
  Widget host(Widget child) => ChangeNotifierProvider.value(
    value: provider,
    child: MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );

  testWidgets('query survives parent rebuilds and replaces its subscription when identity changes', (tester) async {
    var calls = 0;
    var cancels = 0;
    final controllers = <StreamController<int>>[];
    Widget query(String key) => LibraryQueryView<int>(
      queryKey: key,
      initialData: 0,
      query: (_) {
        calls++;
        final controller = StreamController<int>(onCancel: () => cancels++);
        controllers.add(controller);
        controller.add(calls);
        return controller.stream;
      },
      builder: (context, value) => Text('$value'),
    );
    await tester.pumpWidget(host(query('one')));
    await tester.pump();
    await tester.pumpWidget(host(query('one')));
    await tester.pump();
    expect(calls, 1);
    expect(cancels, 0);
    expect(find.text('1'), findsOneWidget);
    await tester.pumpWidget(host(query('two')));
    await tester.pump();
    expect(calls, 2);
    expect(cancels, 1);
    expect(find.text('2'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    expect(cancels, 2);
    for (final controller in controllers) {
      unawaited(controller.close());
    }
  });

  testWidgets('paging expands on scroll and resets when the search changes', (tester) async {
    final limits = <int>[];
    Widget query(String key) => PagedLibraryQueryView<int>(
      queryKey: key,
      query: (_, limit) {
        limits.add(limit);
        return Stream.value(List.generate(limit, (i) => i));
      },
      builder: (context, items) => ListView.builder(
        itemExtent: 40,
        itemCount: items.length,
        itemBuilder: (context, index) => Text('${items[index]}'),
      ),
    );
    await tester.pumpWidget(host(query('one')));
    await tester.pumpAndSettle();
    expect(limits, [100]);
    await tester.drag(find.byType(ListView), const Offset(0, -3500));
    await tester.pumpAndSettle();
    expect(limits, [100, 200]);
    await tester.pumpWidget(host(query('two')));
    await tester.pumpAndSettle();
    expect(limits.last, 100);
    await tester.pumpWidget(const SizedBox());
  });
}
