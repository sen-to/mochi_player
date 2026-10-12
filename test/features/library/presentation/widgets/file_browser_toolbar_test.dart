import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/library/application/file_browser_provider.dart';
import 'package:mochi_player/features/library/presentation/widgets/file_browser_toolbar.dart';
import 'package:mochi_player/l10n/l10n.dart';

void main() {
  testWidgets('exposes the file browser toolbar actions', (tester) async {
    var backCount = 0;
    var refreshCount = 0;
    var sourceSelectionCount = 0;
    String? selectedPath;
    FileBrowserViewMode? selectedViewMode;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            child: FileBrowserToolbar(
              sourceName: '家庭媒体库',
              currentPath: '/quark/电影/',
              canGoBack: false,
              viewMode: FileBrowserViewMode.list,
              sortField: FileSortField.name,
              sortAscending: true,
              onBack: () => backCount++,
              onPathSelected: (path) => selectedPath = path,
              onSortChanged: (_, _) {},
              onViewModeChanged: (mode) => selectedViewMode = mode,
              onRefresh: () => refreshCount++,
              onRootSelected: () => sourceSelectionCount++,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('后退'));
    await tester.tap(find.byTooltip('网格视图'));
    await tester.tap(find.byTooltip('刷新目录'));
    await tester.tap(find.text('根目录'));
    await tester.tap(find.text('quark'));

    expect(backCount, 0);
    expect(selectedViewMode, FileBrowserViewMode.grid);
    expect(refreshCount, 1);
    expect(sourceSelectionCount, 1);
    expect(selectedPath, '/quark/');
  });
}
