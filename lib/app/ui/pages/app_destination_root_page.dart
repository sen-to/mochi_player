// 【应用界面】组装首页与媒体库目的地的标题、搜索和内容。
// 业务查询使用各功能入口，页面只管理展示交互。

import 'package:flutter/material.dart';
import 'package:mochi_player/app/ui/navigation/app_destination.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/home/ui/widgets/home_content.dart';
import 'package:mochi_player/features/library/browser/ui/file_browser_page.dart';
import 'package:mochi_player/features/library/catalog/ui/library_page.dart';
import 'package:mochi_player/features/library/catalog/ui/library_search_results_view.dart';
import 'package:mochi_player/features/library/sources/ui/storage_sources_panel.dart';
import 'package:mochi_player/features/settings/ui/pages/settings_page.dart';
import 'package:mochi_player/l10n/l10n.dart';

class AppDestinationRootPage extends StatelessWidget {
  const AppDestinationRootPage({super.key, required this.destination});

  final AppDestination destination;

  @override
  Widget build(BuildContext context) {
    final content = switch (destination) {
      AppDestination.home => const HomeContent(),
      AppDestination.movies => const LibraryPage(category: LibraryCategory.movies),
      AppDestination.series => const LibraryPage(category: LibraryCategory.series),
      AppDestination.fileBrowser => const FileBrowserPage(),
      AppDestination.favorites => const LibraryPage(category: LibraryCategory.favorites),
      AppDestination.settings => const SettingsPage(mediaSourcesPanel: StorageSourcesPanel()),
    };
    return destination.showsHeader ? _SearchableDestinationPage(destination: destination, content: content) : content;
  }
}

class _SearchableDestinationPage extends StatefulWidget {
  const _SearchableDestinationPage({required this.destination, required this.content});

  final AppDestination destination;
  final Widget content;

  @override
  State<_SearchableDestinationPage> createState() => _SearchableDestinationPageState();
}

class _SearchableDestinationPageState extends State<_SearchableDestinationPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isSearching = _searchQuery.isNotEmpty;
    return Stack(
      children: [
        // 保留原页面及其滚动位置，搜索期间暂停隐藏内容的动画和焦点交互。
        Positioned.fill(
          child: Visibility(visible: !isSearching, maintainState: true, child: widget.content),
        ),
        if (isSearching)
          Positioned.fill(
            child: LibrarySearchResultsView(key: ValueKey(_searchQuery), query: _searchQuery),
          ),
        Positioned(
          key: const ValueKey('media-search-header'),
          top: 0,
          left: 0,
          right: 0,
          height: AppHeader.height,
          child: AppHeader(
            title: widget.destination.title(context),
            trailing: SizedBox(
              width: 240,
              child: AppSearchInput(
                placeholder: context.l10n.searchLibrary,
                clearOnEscape: true,
                onChanged: (value) {
                  final query = value.trim();
                  if (query == _searchQuery) return;
                  setState(() => _searchQuery = query);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
