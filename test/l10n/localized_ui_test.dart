// 【行为测试】验证通过界面上下文获取文案，并将失败语义转换为本地化提示。
// 测试对象的职责边界：语言资源由 ARB 生成，此文件不保存业务状态。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/app_failure.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/library/browser/domain/file_browser_entry.dart';
import 'package:mochi_player/features/library/browser/ui/file_browser_entry_display.dart';
import 'package:mochi_player/features/library/domain/media_file_kind.dart';
import 'package:mochi_player/features/settings/ui/widgets/language_preference_control.dart';
import 'package:mochi_player/l10n/application/app_locale_provider.dart';
import 'package:mochi_player/l10n/data/preferences_language_repository.dart';
import 'package:mochi_player/l10n/l10n.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('connection messages stay concise and scan messages format counts', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final zh = await AppLocalizations.delegate.load(const Locale('zh'));
    expect(en.connectionSucceeded, 'Connected');
    expect(zh.connectionSucceeded, '连接成功');
    expect(en.failure(AppFailure.tmdbRateLimited), 'TMDB request limit reached. Try again later.');
    expect(zh.failure(AppFailure.tmdbAuthentication), 'TMDB 认证失败，请检查 API Key 和访问权限。');
    expect(zh.failure(AppFailure.tmdbTimeout), 'TMDB 请求超时，请检查网络或代理后重试。');
    expect(en.webdavPortRequired, 'Enter the port');
    expect(zh.webdavPortRequired, '请输入端口');
    expect(en.fileCount(0), '0 files');
    expect(en.fileCount(1), '1 file');
    expect(en.fileCount(1234), '1,234 files');
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
    final locales = AppLocaleProvider(repository: PreferencesLanguageRepository());
    await locales.load();
    await locales.setLanguage(AppLanguage.zh);
    var mounts = 0;
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: locales,
        child: Builder(
          builder: (context) => MaterialApp(
            theme: AppTheme.lightTheme,
            locale: context.watch<AppLocaleProvider>().locale,
            localeListResolutionCallback: AppLocaleProvider.resolve,
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
    final locales = AppLocaleProvider(repository: PreferencesLanguageRepository());
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
