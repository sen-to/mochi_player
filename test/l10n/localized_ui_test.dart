import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/app_failure.dart';
import 'package:mochi_player/core/domain/media/media_file_kind.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/library/domain/file_browser_entry.dart';
import 'package:mochi_player/features/library/presentation/widgets/file_browser_entry_display.dart';
import 'package:mochi_player/features/settings/presentation/widgets/language_preference_control.dart';
import 'package:mochi_player/l10n/app_locale_controller.dart';
import 'package:mochi_player/l10n/l10n.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('connection and scan messages format zero, singular, plural and large counts', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final zh = await AppLocalizations.delegate.load(const Locale('zh'));
    expect(en.directoryAccessible(0), 'Folder is accessible (0 items)');
    expect(en.directoryAccessible(1), 'Folder is accessible (1 item)');
    expect(en.connectionAccessible(2), 'Connected. Folder is accessible (2 items).');
    expect(en.connectionAccessible(1234), 'Connected. Folder is accessible (1,234 items).');
    expect(zh.directoryAccessible(1234), '目录可访问（1,234 项）');
    expect(en.sourceDeleted(1), 'Media source deleted; 1 media file removed from the library');
    expect(en.scanSummary(1, 0, 1234), 'Scan complete: 1 video found, 0 added, 1,234 removed');
    expect(en.scanPartialFailure('Scan', 1, 'TMDB'), 'Scan; 1 media source failed to scan; TMDB');
    expect(en.scanPartialFailure('Scan', 2, 'TMDB'), 'Scan; 2 media sources failed to scan; TMDB');
    expect(en.scanResultWithMetadata('Scan', 'TMDB'), 'Scan; TMDB');
    expect(zh.scanResultWithMetadata('扫描', '元数据'), '扫描；元数据');
    expect(en.scanResultWithError('Scan', 'Failed'), 'Scan; Failed');
    expect(zh.scanResultWithError('扫描', '失败'), '扫描；失败');
  });

  testWidgets('language picker switches UI and preserves mounted playback state', (tester) async {
    final locales = AppLocaleController();
    await locales.load();
    await locales.setLanguage(AppLanguage.zh);
    var mounts = 0;
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: locales,
        child: Builder(
          builder: (context) => MaterialApp(
            theme: AppTheme.lightTheme,
            locale: context.watch<AppLocaleController>().locale,
            localeListResolutionCallback: AppLocaleController.resolve,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: Column(
                  children: [
                    Text(context.l10n.settings),
                    const LanguagePreferenceControl(),
                    _SessionProbe(onMount: () => mounts++),
                    Text(context.l10n.fileCount(1)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('设置'), findsOneWidget);
    await tester.tap(find.text('简体中文'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();
    expect(locales.language, AppLanguage.en);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('1 file'), findsOneWidget);
    expect(mounts, 1);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Follow system').last);
    await tester.pumpAndSettle();
    expect(locales.locale, isNull);
    await tester.pumpWidget(const SizedBox());
    locales.dispose();
  });

  testWidgets('dates, plural counts and structured errors follow the current locale', (tester) async {
    final locales = AppLocaleController();
    await locales.setLanguage(AppLanguage.en);
    final item = FileBrowserEntry(
      sourceId: 'test',
      path: '/clip.mkv',
      name: 'clip.mkv',
      kind: MediaFileKind.video,
      size: 2048,
      modifiedAt: DateTime(2026, 7, 4, 14, 30),
    );
    await tester.pumpWidget(
      ListenableBuilder(
        listenable: locales,
        builder: (_, _) => MaterialApp(
          theme: AppTheme.lightTheme,
          locale: locales.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  Text(item.browserModifiedAtLabel(context)),
                  Text(item.browserTypeLabel(context)),
                  Text(context.l10n.fileCount(1234)),
                  Text(context.l10n.failure(AppFailure.filesLoad)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('7/4/2026 14:30'), findsOneWidget);
    expect(find.text('Video'), findsOneWidget);
    expect(find.text('1,234 files'), findsOneWidget);
    expect(find.text('Could not load files'), findsOneWidget);
    await locales.setLanguage(AppLanguage.zh);
    await tester.pumpAndSettle();
    expect(find.text('2026/7/4 14:30'), findsOneWidget);
    expect(find.text('视频'), findsOneWidget);
    expect(find.text('1,234 个文件'), findsOneWidget);
    expect(find.text('文件加载失败'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    locales.dispose();
  });

  testWidgets('standard input menu uses the selected Material locale', (tester) async {
    final input = TextEditingController(text: 'Example');
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: AppInput(controller: input)),
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(AppInput));
    expect(context.l10n.applicationLanguage, 'Application language');
    expect(MaterialLocalizations.of(context).copyButtonLabel, 'Copy');
    expect(context.l10n.fileCount(0), '0 files');
    expect(context.l10n.fileCount(2), '2 files');
    expect(context.l10n.seasonEpisodeLabel(2, 7), 'Season 2 · Episode 7');
    await tester.pumpWidget(const SizedBox());
    input.dispose();
  });
}

class _SessionProbe extends StatefulWidget {
  const _SessionProbe({required this.onMount});

  final VoidCallback onMount;

  @override
  State<_SessionProbe> createState() => _SessionProbeState();
}

class _SessionProbeState extends State<_SessionProbe> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
