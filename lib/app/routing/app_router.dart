import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mochi_player/app/presentation/navigation/app_destination.dart';
import 'package:mochi_player/app/presentation/pages/app_destination_root_page.dart';
import 'package:mochi_player/app/presentation/pages/app_shell_page.dart';
import 'package:mochi_player/core/domain/media/library_item.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/library/presentation/pages/library_section_page.dart';
import 'package:mochi_player/features/library/presentation/pages/media_detail_page.dart';

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: AppDestination.home.path,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShellPage(navigationShell: navigationShell),
        branches: [for (final destination in AppDestination.values) _buildDestinationBranch(destination)],
      ),
    ],
  );
}

StatefulShellBranch _buildDestinationBranch(AppDestination destination) {
  return StatefulShellBranch(
    routes: [
      GoRoute(
        path: destination.path,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: AppDestinationRootPage(destination: destination),
        ),
        routes: [
          if (destination == AppDestination.home)
            GoRoute(
              path: 'section/:section',
              pageBuilder: (context, state) {
                final section = LibrarySection.values.asNameMap()[state.pathParameters['section']];
                if (section == null) {
                  return _errorPage(state, '未知的媒体库分区');
                }
                return _appTransitionPage(
                  state: state,
                  child: LibrarySectionPage(section: section),
                );
              },
            ),
          if (_supportsMediaDetail(destination))
            GoRoute(
              path: 'media',
              pageBuilder: (context, state) {
                final item = state.extra;
                if (item is! LibraryItem) {
                  return _errorPage(state, '缺少媒体详情参数');
                }
                return _appTransitionPage(
                  state: state,
                  child: MediaDetailPage(item: item),
                );
              },
            ),
        ],
      ),
    ],
  );
}

bool _supportsMediaDetail(AppDestination destination) {
  return switch (destination) {
    AppDestination.home || AppDestination.movies || AppDestination.series || AppDestination.favorites => true,
    AppDestination.fileBrowser || AppDestination.settings => false,
  };
}

CustomTransitionPage<void> _appTransitionPage({required GoRouterState state, required Widget child}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutQuart,
        reverseCurve: Curves.easeInCubic,
      );
      final position = Tween<Offset>(begin: const Offset(0.025, 0), end: Offset.zero).animate(curvedAnimation);

      return FadeTransition(
        opacity: curvedAnimation,
        child: SlideTransition(position: position, child: child),
      );
    },
  );
}

MaterialPage<void> _errorPage(GoRouterState state, String message) {
  return MaterialPage<void>(
    key: state.pageKey,
    child: Scaffold(
      body: AppResult(status: AppResultStatus.error, title: '页面无法打开', subtitle: message),
    ),
  );
}
