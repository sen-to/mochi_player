// 【应用界面】展示应用外壳、导航分支及共享任务提示。
// 启动时加载媒体库和趋势，资源所有权留在应用入口。

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mochi_player/app/ui/navigation/app_destination.dart';
import 'package:mochi_player/app/ui/widgets/app_sidebar.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/home/application/trending_media_provider.dart';
import 'package:mochi_player/features/library/application/media_library_provider.dart';
import 'package:mochi_player/features/settings/application/app_settings_provider.dart';
import 'package:mochi_player/l10n/l10n.dart';
import 'package:provider/provider.dart';

class AppShellPage extends StatefulWidget {
  const AppShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeApp());
  }

  Future<void> _initializeApp() async {
    final settingsProvider = context.read<AppSettingsProvider>();
    final libraryProvider = context.read<MediaLibraryProvider>();
    final trendingProvider = context.read<TrendingMediaProvider>();

    await libraryProvider.loadFromDatabase();
    if (settingsProvider.hasTmdbApiKey) {
      await trendingProvider.fetch();
    }
  }

  void _selectDestination(AppDestination destination) {
    widget.navigationShell.goBranch(
      destination.index,
      initialLocation: destination.index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            selectedDestination: AppDestination.values[widget.navigationShell.currentIndex],
            onDestinationSelected: _selectDestination,
          ),
          Expanded(
            child: AppMessageHost(
              top: AppHeader.height + AppSpacing.sm,
              child: ColoredBox(
                color: theme.scaffoldBackgroundColor,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(child: widget.navigationShell),
                    Selector<MediaLibraryProvider, _LibraryActivitySnapshot>(
                      selector: (context, provider) => _LibraryActivitySnapshot(
                        message: provider.libraryActivity == null
                            ? null
                            : context.l10n.activity(provider.libraryActivity!),
                        progress: provider.scrapeProgress,
                      ),
                      builder: (context, activity, child) {
                        final message = activity.message;
                        if (message == null) return const SizedBox.shrink();

                        return Positioned(
                          top: AppHeader.height + 10,
                          left: AppSpacing.page,
                          right: AppSpacing.page,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: AppProgressNotice(message: message, progress: activity.progress),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryActivitySnapshot {
  final String? message;
  final double? progress;

  const _LibraryActivitySnapshot({required this.message, required this.progress});

  @override
  bool operator ==(Object other) {
    return other is _LibraryActivitySnapshot && other.message == message && other.progress == progress;
  }

  @override
  int get hashCode => Object.hash(message, progress);
}
