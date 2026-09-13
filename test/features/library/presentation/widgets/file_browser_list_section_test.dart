import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/media/media_file_kind.dart';
import 'package:mochi_player/core/ui/theme/app_theme.dart';
import 'package:mochi_player/features/library/domain/file_browser_entry.dart';
import 'package:mochi_player/features/library/presentation/widgets/file_browser_list.dart';

void main() {
  testWidgets('handles transient layout heights smaller than the summary', (tester) async {
    final item = FileBrowserEntry(
      path: '/movie.mkv',
      name: 'movie.mkv',
      kind: MediaFileKind.video,
      size: 1024,
      modifiedAt: null,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 600,
            height: 20,
            child: FileBrowserListSection(
              items: [item],
              totalItemCount: 1,
              isFiltered: false,
              onItemTap: (_) {},
              scrollStorageKey: const PageStorageKey<String>('test-file-browser-list'),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 600,
            height: 60,
            child: FileBrowserListSection(
              items: [item],
              totalItemCount: 1,
              isFiltered: false,
              onItemTap: (_) {},
              scrollStorageKey: const PageStorageKey<String>('test-file-browser-list'),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('accounts for dividers when sizing a short list', (tester) async {
    final items = List.generate(
      2,
      (index) => FileBrowserEntry(
        path: '/folder-$index',
        name: 'folder-$index',
        kind: MediaFileKind.directory,
        size: 0,
        modifiedAt: null,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: SizedBox(
          width: 600,
          height: 400,
          child: FileBrowserListSection(
            items: items,
            totalItemCount: items.length,
            isFiltered: false,
            onItemTap: (_) {},
            scrollStorageKey: const PageStorageKey<String>('test-file-browser-list'),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(FileBrowserList)).height,
      FileBrowserList.headerHeight +
          2 * FileBrowserList.borderWidth +
          FileBrowserList.dividerHeight +
          items.length * FileBrowserList.rowHeight +
          FileBrowserList.dividerHeight,
    );
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.maxScrollExtent, 0);
  });
}
