import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:mochi_player/app/presentation/navigation/app_destination.dart';

abstract final class AppRoutePaths {
  static String destination(AppDestination destination) => destination.path;

  static String mediaDetail(BuildContext context) => '${currentDestination(context).path}/media';

  static String librarySection(String sectionName) => '${AppDestination.home.path}/section/$sectionName';

  static AppDestination currentDestination(BuildContext context) {
    final segments = GoRouterState.of(context).uri.pathSegments;
    if (segments.isEmpty) return AppDestination.home;

    return AppDestination.values.firstWhere(
      (destination) => destination.pathSegment == segments.first,
      orElse: () => AppDestination.home,
    );
  }
}
