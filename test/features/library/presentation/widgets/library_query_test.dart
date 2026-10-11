import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/infrastructure/database/app_database.dart';
import 'package:mochi_player/core/infrastructure/database/database_service.dart';
import 'package:mochi_player/core/infrastructure/database/sqlite_setup.dart';
import 'package:mochi_player/features/library/application/media_library_provider.dart';
import 'package:mochi_player/features/library/presentation/widgets/library_query.dart';
import 'package:provider/provider.dart';

void main() {
  late DatabaseService db;
  late MediaLibraryProvider provider;
  setUp(() async {
    db = DatabaseService.withDatabase(AppDatabase(NativeDatabase.memory(setup: configureSqlite)));
    await db.init();
    provider = MediaLibraryProvider(database: db);
  });
  tearDown(() async {
    provider.dispose();
    await db.close();
  });
  Widget host(Widget child) => ChangeNotifierProvider.value(
    value: provider,
    child: MaterialApp(home: Scaffold(body: child)),
  );

  testWidgets('query survives parent rebuilds and replaces its subscription when identity changes', (tester) async {
    var calls = 0;
    var cancels = 0;
    final controllers = <StreamController<int>>[];
    Widget query(String key) => LibraryQuery<int>(
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
    Widget query(String key) => PagedLibraryQuery<int>(
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
