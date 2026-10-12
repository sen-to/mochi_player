import 'package:flutter/widgets.dart';
import 'package:mochi_player/core/ui/theme/app_icons.dart';
import 'package:mochi_player/l10n/l10n.dart';

enum AppDestination {
  home(pathSegment: 'home', icon: AppIcons.libraryHome, showsHeader: true),
  movies(pathSegment: 'movies', icon: AppIcons.movies, showsHeader: true),
  series(pathSegment: 'series', icon: AppIcons.series, showsHeader: true),
  fileBrowser(pathSegment: 'files', icon: AppIcons.fileBrowser),
  favorites(pathSegment: 'favorites', icon: AppIcons.favorites, showsHeader: true),
  settings(pathSegment: 'settings', icon: AppIcons.settings);

  final String pathSegment;

  final IconData icon;
  final bool showsHeader;

  const AppDestination({required this.pathSegment, required this.icon, this.showsHeader = false});

  String title(BuildContext context) => switch (this) {
    home => context.l10n.home,
    movies => context.l10n.movies,
    series => context.l10n.series,
    fileBrowser => context.l10n.fileBrowser,
    favorites => context.l10n.favorites,
    settings => context.l10n.settings,
  };

  String get path => '/$pathSegment';
}
