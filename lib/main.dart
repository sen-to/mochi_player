import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:mochi_player/app/routing/app_router.dart';
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
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  final currentWindow = await WindowController.fromCurrentEngine();
  final playerWindowRequest = PlayerWindowRequest.tryDecode(currentWindow.arguments);
  if (playerWindowRequest != null) {
    await runPlayerWindow(currentWindow, playerWindowRequest);
    return;
  }
  await windowManager.ensureInitialized();

  // 初始化数据库
  await DatabaseService().init();

  final appSettingsProvider = AppSettingsProvider();
  await appSettingsProvider.load();
  final mediaLibraryProvider = MediaLibraryProvider();
  await PlayerWindow.installMainWindowHandler(
    currentWindow,
    onPlaybackStateChanged: (changedMedia) => mediaLibraryProvider.refreshPlaybackState(
      changedMedia.map((key) => (sourceId: key.sourceId, path: key.path)).toList(growable: false),
    ),
  );
  final windowControlsController = WindowControlsController();

  final windowOptions = WindowOptions(
    size: const Size(1200, 800),
    minimumSize: const Size(900, 600),
    center: true,
    title: 'Mochi Player',
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: Platform.isWindows ? TitleBarStyle.normal : TitleBarStyle.hidden,
    windowButtonVisibility: Platform.isMacOS,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    if (Platform.isMacOS) {
      await windowControlsController.positionNativeWindowButtons();
    }
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appSettingsProvider),
        ChangeNotifierProvider.value(value: windowControlsController),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FileBrowserProvider()),
        ChangeNotifierProvider.value(value: mediaLibraryProvider),
        ChangeNotifierProvider(create: (_) => TrendingMediaProvider()),
      ],
      child: MochiPlayerApp(router: createAppRouter()),
    ),
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
