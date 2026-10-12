import 'package:flutter/material.dart';
import 'package:mochi_player/app/presentation/navigation/app_destination.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/home/presentation/widgets/home_content.dart';
import 'package:mochi_player/features/library/presentation/pages/file_browser_page.dart';
import 'package:mochi_player/features/library/presentation/pages/library_page.dart';
import 'package:mochi_player/features/settings/presentation/pages/settings_page.dart';
import 'package:mochi_player/l10n/l10n.dart';

class AppDestinationRootPage extends StatelessWidget {
  const AppDestinationRootPage({super.key, required this.destination});

  final AppDestination destination;

  @override
  Widget build(BuildContext context) {
    return switch (destination) {
      AppDestination.home => const _HomeDestinationPage(),
      AppDestination.movies => const _LibraryDestinationPage(
        destination: AppDestination.movies,
        category: LibraryCategory.movies,
      ),
      AppDestination.series => const _LibraryDestinationPage(
        destination: AppDestination.series,
        category: LibraryCategory.series,
      ),
      AppDestination.fileBrowser => const FileBrowserPage(),
      AppDestination.favorites => const _LibraryDestinationPage(
        destination: AppDestination.favorites,
        category: LibraryCategory.favorites,
      ),
      AppDestination.settings => const SettingsPage(),
    };
  }
}

class _HomeDestinationPage extends StatefulWidget {
  const _HomeDestinationPage();

  @override
  State<_HomeDestinationPage> createState() => _HomeDestinationPageState();
}

class _HomeDestinationPageState extends State<_HomeDestinationPage> {
  double _scrollOffset = 0;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final headerOpacity = (_scrollOffset / 200).clamp(0.0, 1.0);

    return Stack(
      children: [
        Positioned.fill(
          child: HomeContent(
            searchQuery: _searchQuery,
            onScroll: (offset) {
              if (offset == _scrollOffset) return;
              setState(() => _scrollOffset = offset);
            },
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: AppHeader.height,
          child: AppHeader(
            title: AppDestination.home.title(context),
            trailing: SizedBox(
              width: 240,
              child: AppSearchInput(
                placeholder: context.l10n.searchLibrary,
                onChanged: (query) {
                  if (query == _searchQuery) return;
                  setState(() => _searchQuery = query);
                },
              ),
            ),
            visibility: headerOpacity,
          ),
        ),
      ],
    );
  }
}

class _LibraryDestinationPage extends StatefulWidget {
  const _LibraryDestinationPage({required this.destination, required this.category});

  final AppDestination destination;
  final LibraryCategory category;

  @override
  State<_LibraryDestinationPage> createState() => _LibraryDestinationPageState();
}

class _LibraryDestinationPageState extends State<_LibraryDestinationPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: LibraryPage(category: widget.category, searchQuery: _searchQuery),
        ),
        if (widget.destination.showsHeader)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: AppHeader.height,
            child: AppHeader(
              title: widget.destination.title(context),
              trailing: SizedBox(
                width: 240,
                child: AppSearchInput(
                  placeholder: _searchHint(widget.category),
                  onChanged: (query) {
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

  String _searchHint(LibraryCategory category) {
    return switch (category) {
      LibraryCategory.movies => context.l10n.searchMovies,
      LibraryCategory.series => context.l10n.searchSeries,
      LibraryCategory.favorites => context.l10n.searchFavorites,
    };
  }
}
