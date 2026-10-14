import 'package:flutter/material.dart';
import 'package:mochi_player/core/domain/playback/playback_target_resolver.dart';
import 'package:mochi_player/core/platform/window_controls_controller.dart';
import 'package:mochi_player/core/ui/theme/app_theme.dart';
import 'package:mochi_player/core/ui/components/feedback/app_message.dart';
import 'package:mochi_player/features/playback/application/playback_engine.dart';
import 'package:mochi_player/features/playback/application/player_window_state.dart';
import 'package:mochi_player/features/playback/presentation/controllers/player_window_close_coordinator.dart';
import 'package:mochi_player/features/playback/presentation/pages/player_page.dart';
import 'package:mochi_player/features/settings/application/theme_provider.dart';
import 'package:mochi_player/l10n/app_locale_controller.dart';
import 'package:mochi_player/l10n/l10n.dart';
import 'package:provider/provider.dart';

class PlayerWindowApp extends StatelessWidget {
  const PlayerWindowApp({
    super.key,
    required this.session,
    required this.closeCoordinator,
    required this.onCloseRequested,
    required this.windowControls,
    required this.engineFactory,
    required this.resolver,
  });

  final PlayerWindowState session;
  final PlayerWindowCloseCoordinator closeCoordinator;
  final Future<void> Function() onCloseRequested;
  final WindowControlsController windowControls;
  final PlaybackEngine Function(PlaybackOptions) engineFactory;
  final PlaybackTargetResolver resolver;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: windowControls),
        ChangeNotifierProvider.value(value: session),
      ],
      child: Consumer2<ThemeProvider, AppLocaleController>(
        builder: (context, themeProvider, locales, _) {
          return MaterialApp(
            title: 'Mochi Player',
            locale: locales.locale,
            localeListResolutionCallback: AppLocaleController.resolve,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: AppTheme.lightThemeFor(themeProvider.accentColor.color),
            darkTheme: AppTheme.darkThemeFor(themeProvider.accentColor.color),
            home: AppMessageHost(
              child: Consumer<PlayerWindowState>(
                builder: (context, session, _) => _PlayerWindowHome(
                  bootstrap: session.bootstrap,
                  engineFactory: engineFactory,
                  resolver: resolver,
                  isOpen: session.isOpen,
                  isClosing: session.isClosing,
                  closeCoordinator: closeCoordinator,
                  onCloseRequested: onCloseRequested,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlayerWindowHome extends StatelessWidget {
  const _PlayerWindowHome({
    required this.bootstrap,
    required this.engineFactory,
    required this.resolver,
    required this.isOpen,
    required this.isClosing,
    required this.closeCoordinator,
    required this.onCloseRequested,
  });

  final PlayerWindowBootstrap bootstrap;
  final PlaybackEngine Function(PlaybackOptions) engineFactory;
  final PlaybackTargetResolver resolver;
  final bool isOpen;
  final bool isClosing;
  final PlayerWindowCloseCoordinator closeCoordinator;
  final Future<void> Function() onCloseRequested;

  @override
  Widget build(BuildContext context) {
    return ExcludeFocus(
      excluding: isClosing,
      child: IgnorePointer(
        ignoring: isClosing,
        child: SizedBox.expand(
          child: !isOpen
              ? const ColoredBox(color: Colors.black)
              : bootstrap.isReady
              ? PlayerPage(
                  key: ValueKey(bootstrap.request.requestId),
                  videoItem: bootstrap.initialMedia!,
                  engineFactory: engineFactory,
                  resolver: resolver,
                  target: bootstrap.initialTarget!,
                  contextTitle: bootstrap.request.contextTitle,
                  playlist: bootstrap.queue,
                  mediaStore: bootstrap.mediaStore,
                  regularMinimumWindowSize: const Size(720, 405),
                  closeCoordinator: closeCoordinator,
                )
              : _PlayerWindowLaunchFailure(bootstrap: bootstrap, onCloseRequested: onCloseRequested),
        ),
      ),
    );
  }
}

class _PlayerWindowLaunchFailure extends StatelessWidget {
  const _PlayerWindowLaunchFailure({required this.bootstrap, required this.onCloseRequested});

  final PlayerWindowBootstrap bootstrap;
  final Future<void> Function() onCloseRequested;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 36),
                const SizedBox(height: 16),
                Text(context.l10n.playerUnavailable, style: TextStyle(color: Colors.white, fontSize: 20)),
                const SizedBox(height: 8),
                Text(
                  bootstrap.failure == PlayerLaunchFailure.load
                      ? context.l10n.playerBootstrapFailed
                      : context.l10n.playerTargetFailed,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                FilledButton(onPressed: onCloseRequested, child: Text(context.l10n.close)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
