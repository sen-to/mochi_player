import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/platform/window_controls_layout.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/playback/presentation/widgets/player_overlay.dart';

void main() {
  testWidgets('aligns title with the safe inset after macOS window controls', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await tester.pumpWidget(
        _testApp(
          PlayerTopBar(
            title: '进击的巨人',
            secondaryTitle: '第 1 季 · 第 1 集',
            cacheSpeed: '3.2 MB/s',
            isFullScreen: false,
          ),
        ),
      );

      expect(
        tester.getTopLeft(find.text('进击的巨人')).dx,
        WindowControlsLayout.leadingContentInset,
      );
      expect(find.text('进击的巨人'), findsOneWidget);
      expect(find.text('第 1 季 · 第 1 集'), findsOneWidget);
      expect(find.byKey(const ValueKey('player-back-button')), findsNothing);

      final cacheSpeed = find.byKey(const ValueKey('player-cache-speed'));
      expect(tester.getTopRight(cacheSpeed).dx, 1176);
      expect(find.text('3.2 MB/s'), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      debugDefaultTargetPlatformOverride = null;
    }
  });

  test('uses the same leading content inset on Windows and macOS', () {
    expect(
      PlayerOverlayLayout.topLeftInset(
        platform: TargetPlatform.windows,
        isFullScreen: false,
      ),
      PlayerOverlayLayout.topLeftInset(
        platform: TargetPlatform.macOS,
        isFullScreen: false,
      ),
    );
  });

  testWidgets('uses the regular page inset in fullscreen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _testApp(
        PlayerTopBar(title: '电影', cacheSpeed: '3.2 MB/s', isFullScreen: true),
      ),
    );

    expect(tester.getTopLeft(find.text('电影')).dx, AppSpacing.xxl);
  });

  testWidgets('hides the cache speed when it is unavailable', (tester) async {
    await tester.pumpWidget(
      _testApp(PlayerTopBar(title: '电影', cacheSpeed: '', isFullScreen: true)),
    );

    expect(find.byKey(const ValueKey('player-cache-speed')), findsNothing);
  });

  testWidgets(
    'keeps the bottom glass panel inset and progress above controls',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _testApp(
          const Align(
            alignment: Alignment.bottomCenter,
            child: PlayerBottomControlBar(
              progress: SizedBox(key: ValueKey('progress'), height: 10),
              controls: SizedBox(
                key: ValueKey('controls'),
                height: PlayerOverlayLayout.controlHeight,
              ),
            ),
          ),
        ),
      );

      final panel = find.byKey(const ValueKey('player-bottom-control-bar'));
      expect(tester.getTopLeft(panel).dx, 252);
      expect(tester.getTopRight(panel).dx, 948);
      expect(tester.getSize(panel).height, 64);
      expect(tester.getBottomRight(panel).dy, 700 - AppSpacing.md);
      final glass = tester.widget<AppGlassSurface>(panel);
      expect(glass.color, PlayerOverlayGlass.background);
      expect(glass.borderColor, PlayerOverlayGlass.border);
      expect(glass.blur, PlayerOverlayGlass.blur);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('progress'))).dy,
        lessThan(tester.getTopLeft(find.byKey(const ValueKey('controls'))).dy),
      );
    },
  );

  testWidgets('lets the bottom control bar move within the player bounds', (
    tester,
  ) async {
    var buttonPresses = 0;
    Rect? reportedBounds;
    await tester.binding.setSurfaceSize(const Size(1200, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _testApp(
        Align(
          alignment: Alignment.bottomCenter,
          child: PlayerBottomControlBar(
            onBoundsChanged: (bounds) => reportedBounds = bounds,
            progress: const SizedBox(height: 10),
            controls: PlayerControlButton(
              key: const ValueKey('test-player-control'),
              onPressed: () => buttonPresses++,
              child: const Icon(Icons.play_arrow_rounded),
            ),
          ),
        ),
      ),
    );

    final panel = find.byKey(const ValueKey('player-bottom-control-bar'));
    final originalTopLeft = tester.getTopLeft(panel);
    expect(reportedBounds?.topLeft, originalTopLeft);
    expect(
      find.byKey(const ValueKey('player-control-bar-drag-handle')),
      findsNothing,
    );
    await tester.dragFrom(
      originalTopLeft +
          Offset(
            tester.getSize(panel).width - 8,
            tester.getSize(panel).height - 8,
          ),
      const Offset(80, -100),
    );
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(panel), originalTopLeft + const Offset(80, -100));
    expect(reportedBounds?.topLeft, originalTopLeft + const Offset(80, -100));
    await tester.tap(find.byKey(const ValueKey('test-player-control')));
    expect(buttonPresses, 1);
  });

  test('uses a compact width in regular and mini-player windows', () {
    expect(PlayerOverlayLayout.bottomPanelWidth(1200), 696);
    expect(PlayerOverlayLayout.bottomPanelWidth(480), 448);
    expect(PlayerOverlayLayout.bottomPanelWidth(2400), 1040);
  });

  test('scales subtitle text continuously with the player viewport', () {
    expect(
      PlayerSubtitleSizing.fontSize(
        configuredFontSize: 32,
        viewportSize: const Size(1200, 700),
      ),
      32,
    );
    expect(
      PlayerSubtitleSizing.fontSize(
        configuredFontSize: 32,
        viewportSize: const Size(480, 300),
      ),
      12.8,
    );
    expect(
      PlayerSubtitleSizing.fontSize(
        configuredFontSize: 32,
        viewportSize: const Size(900, 600),
      ),
      24,
    );
  });

  testWidgets(
    'keeps subtitles at the bottom unless the control bar overlaps them',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      Widget subtitleLayout(Rect controlBarBounds) => _testApp(
        PlayerSubtitleAvoidingControls(
          controlsVisible: true,
          isMiniPlayer: false,
          controlBarBounds: controlBarBounds,
          child: const SizedBox(
            key: ValueKey('test-subtitle'),
            width: 240,
            height: 40,
          ),
        ),
      );

      await tester.pumpWidget(
        subtitleLayout(const Rect.fromLTWH(252, 624, 696, 64)),
      );
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('test-subtitle'))).dy,
        580,
      );

      await tester.pumpWidget(
        subtitleLayout(const Rect.fromLTWH(252, 524, 696, 64)),
      );
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('test-subtitle'))).dy,
        640,
      );
    },
  );

  testWidgets('keeps subtitles at the bottom while controls are hidden', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _testApp(
        const PlayerSubtitleAvoidingControls(
          controlsVisible: false,
          isMiniPlayer: false,
          controlBarBounds: Rect.fromLTWH(252, 624, 696, 64),
          child: SizedBox(
            key: ValueKey('test-subtitle'),
            width: 240,
            height: 40,
          ),
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.byKey(const ValueKey('test-subtitle'))).dy,
      640,
    );
  });

  testWidgets('mini-player exposes playback, pin and restore controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        Center(
          child: PlayerMiniControls(
            isPlaying: true,
            isAlwaysOnTop: true,
            onPlayPause: () {},
            onToggleAlwaysOnTop: () {},
            onRestoreWindow: () {},
          ),
        ),
      ),
    );

    expect(find.byType(PlayerControlButton), findsNothing);
    expect(find.byType(Tooltip), findsNothing);
    expect(
      tester.getSize(find.byKey(const ValueKey('player-mini-controls'))),
      const Size(106, 38),
    );
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    expect(find.byIcon(Icons.push_pin_rounded), findsOneWidget);
    expect(find.byIcon(Icons.open_in_full_rounded), findsOneWidget);
  });
}

Widget _testApp(Widget child) {
  return MaterialApp(
    theme: AppTheme.darkTheme.copyWith(platform: TargetPlatform.macOS),
    home: Scaffold(
      backgroundColor: Colors.black,
      body: MediaQuery(
        data: const MediaQueryData(size: Size(1200, 700)),
        child: SizedBox(width: 1200, height: 700, child: child),
      ),
    ),
  );
}
