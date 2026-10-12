import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:mochi_player/app/routing/app_router.dart';
import 'package:mochi_player/app/application/application_exit_coordinator.dart';
import 'package:mochi_player/app/application/main_window_lifecycle.dart';
import 'package:mochi_player/core/platform/desktop_window_service.dart';
import 'package:mochi_player/core/platform/window_service.dart';
import 'package:mochi_player/core/infrastructure/database/database_service.dart';
import 'package:mochi_player/core/platform/window_controls_controller.dart';
import 'package:mochi_player/core/ui/theme/app_theme.dart';
import 'package:mochi_player/features/home/application/trending_media_provider.dart';
import 'package:mochi_player/features/library/application/file_browser_provider.dart';
import 'package:mochi_player/features/library/application/media_library_provider.dart';
import 'package:mochi_player/features/playback/domain/player_window_request.dart';
import 'package:mochi_player/features/playback/presentation/player_window_app.dart';
import 'package:mochi_player/features/settings/application/app_settings_provider.dart';
import 'package:mochi_player/features/settings/application/theme_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  final windows = WindowService.instance = DesktopWindowService();
  final currentWindow = await windows.current();
  final playerWindowRequest = PlayerWindowRequest.tryDecode(currentWindow.arguments);
  if (playerWindowRequest != null) {
    await runPlayerWindow(currentWindow, playerWindowRequest);
    return;
  }
  await windows.initialize();

  // 初始化数据库
  await DatabaseService().init();

  final appSettingsProvider = AppSettingsProvider();
  await appSettingsProvider.load();
  final mediaLibraryProvider = MediaLibraryProvider();
  await PlayerWindow.coordinator.installMainWindowHandler(
    currentWindow,
    onPlaybackStateChanged: (changedMedia) => mediaLibraryProvider.refreshPlaybackState(
      changedMedia.map((key) => (sourceId: key.sourceId, path: key.path)).toList(growable: false),
    ),
  );
  final windowControlsController = WindowControlsController();

  final themeProvider = ThemeProvider();
  final exiting = ValueNotifier(false);
  final exitCoordinator = ApplicationExitCoordinator(
    beginShutdown: () {
      exiting.value = true;
      PlayerWindow.coordinator.beginShutdown();
      mediaLibraryProvider.beginShutdown();
      appSettingsProvider.beginShutdown();
      themeProvider.beginShutdown();
    },
    closePlayers: PlayerWindow.coordinator.closeAll,
    cleanUp: () async {
      await Future.wait([
        mediaLibraryProvider.shutdown(),
        appSettingsProvider.waitForPendingSave(),
        themeProvider.waitForPendingSave(),
      ]);
      await DatabaseService().close();
    },
    exitProcess: windows.exitApplication,
    onFailure: (stage, _) => debugPrint('应用退出阶段失败或超时: $stage'),
  );
  await MainWindowLifecycle(windows, exitCoordinator).install();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appSettingsProvider),
        ChangeNotifierProvider.value(value: windowControlsController),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => FileBrowserProvider()),
        ChangeNotifierProvider.value(value: mediaLibraryProvider),
        ChangeNotifierProvider(create: (_) => TrendingMediaProvider()),
      ],
      child: ValueListenableBuilder<bool>(
        valueListenable: exiting,
        child: MochiPlayerApp(router: createAppRouter()),
        builder: (context, isExiting, child) => ExcludeFocus(
          excluding: isExiting,
          child: IgnorePointer(ignoring: isExiting, child: child),
        ),
      ),
    ),
  );
  unawaited(
    windows
        .configure(
          const WindowSetup(size: Size(1200, 800), minimumSize: Size(900, 600), backgroundColor: Colors.transparent),
        )
        .then((_) async {
          if (!exitCoordinator.isExiting && Platform.isMacOS) {
            await windowControlsController.positionNativeWindowButtons();
          }
        }),
  );
}

class MochiPlayerApp extends StatelessWidget {
  const MochiPlayerApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp.router(
      routerConfig: router,
      title: 'Mochi Player',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      themeAnimationDuration: kThemeAnimationDuration,
      themeAnimationCurve: Curves.linear,

      // 直接使用从 AppTheme 类中导入的主题
      theme: AppTheme.lightThemeFor(themeProvider.accentColor.color),
      darkTheme: AppTheme.darkThemeFor(themeProvider.accentColor.color),

      builder: (context, child) {
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
