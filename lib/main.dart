import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mochi_player/app/application/application_exit_coordinator.dart';
import 'package:mochi_player/app/application/main_window_lifecycle.dart';
import 'package:mochi_player/app/routing/app_router.dart';
import 'package:mochi_player/core/infrastructure/database/database_service.dart';
import 'package:mochi_player/core/platform/desktop_window_service.dart';
import 'package:mochi_player/core/platform/window_controls_controller.dart';
import 'package:mochi_player/core/platform/window_service.dart';
import 'package:mochi_player/core/ui/theme/app_theme.dart';
import 'package:mochi_player/features/home/application/trending_media_provider.dart';
import 'package:mochi_player/features/library/application/file_browser_provider.dart';
import 'package:mochi_player/features/library/application/media_library_provider.dart';
import 'package:mochi_player/features/playback/application/player_window_coordinator.dart';
import 'package:mochi_player/features/playback/infrastructure/media_kit_playback_engine.dart';
import 'package:mochi_player/features/playback/presentation/player_window_app.dart';
import 'package:mochi_player/features/settings/application/app_settings_provider.dart';
import 'package:mochi_player/features/settings/application/theme_provider.dart';
import 'package:mochi_player/l10n/app_locale_controller.dart';
import 'package:mochi_player/l10n/l10n.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKitPlaybackEngine.initialize();
  final host = DesktopWindowHost();

  // 初始化数据库
  await DatabaseService().init();

  final locales = AppLocaleController();
  await locales.load();
  final appSettingsProvider = AppSettingsProvider();
  await appSettingsProvider.load();
  final mediaLibraryProvider = MediaLibraryProvider();
  final playerWindows = PlayerWindowCoordinator(
    createSession: (request) => createPlayerWindow(host: host, request: request),
  );
  late final WindowControlsController windowControlsController;
  final router = createAppRouter();
  final exiting = ValueNotifier(false);
  final windows = host.create(
    setup: const WindowSetup(size: Size(1200, 800), minimumSize: Size(900, 600)),
    builder: (_) => ChangeNotifierProvider.value(
      value: windowControlsController,
      child: ValueListenableBuilder<bool>(
        valueListenable: exiting,
        child: MochiPlayerApp(router: router),
        builder: (context, isExiting, child) => ExcludeFocus(
          excluding: isExiting,
          child: IgnorePointer(ignoring: isExiting, child: child),
        ),
      ),
    ),
  );
  windowControlsController = WindowControlsController(viewId: windows.viewId);

  final themeProvider = ThemeProvider();
  final exitCoordinator = ApplicationExitCoordinator(
    beginShutdown: () {
      exiting.value = true;
      locales.beginShutdown();
      playerWindows.beginShutdown();
      mediaLibraryProvider.beginShutdown();
      appSettingsProvider.beginShutdown();
      themeProvider.beginShutdown();
    },
    closePlayers: playerWindows.closeAll,
    cleanUp: () async {
      await Future.wait([
        mediaLibraryProvider.shutdown(),
        appSettingsProvider.waitForPendingSave(),
        themeProvider.waitForPendingSave(),
        locales.drain(),
      ]);
      await DatabaseService().close();
    },
    exitProcess: windows.exitApplication,
    onFailure: (stage, _) => debugPrint('应用退出阶段失败或超时: $stage'),
  );
  await MainWindowLifecycle(windows, exitCoordinator).install();

  runWidget(
    MultiProvider(
      providers: [
        Provider<PlayerWindowCoordinator>.value(value: playerWindows),
        ChangeNotifierProvider.value(value: locales),
        ChangeNotifierProvider.value(value: appSettingsProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => FileBrowserProvider()),
        ChangeNotifierProvider.value(value: mediaLibraryProvider),
        ChangeNotifierProvider(create: (_) => TrendingMediaProvider()),
      ],
      child: host.buildRoot(),
    ),
  );
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!exitCoordinator.isExiting) unawaited(windowControlsController.positionNativeWindowButtons());
  });
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
      locale: context.watch<AppLocaleController>().locale,
      localeListResolutionCallback: AppLocaleController.resolve,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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
