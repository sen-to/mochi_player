// 【本地化入口】通过界面上下文获取文案，并将失败语义转换为本地化提示。
// 语言资源由 ARB 生成，此文件不保存业务状态。

import 'package:flutter/widgets.dart';
import 'package:mochi_player/core/domain/app_failure.dart';
import 'package:mochi_player/core/domain/media/library_activity.dart';
import 'package:mochi_player/l10n/generated/app_localizations.dart';

export 'package:mochi_player/l10n/generated/app_localizations.dart';

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension LocalizedFailures on AppLocalizations {
  String failure(AppFailure failure) => switch (failure) {
    AppFailure.settingsLoad => settingsLoadFailed,
    AppFailure.settingsSave => settingsSaveFailed,
    AppFailure.sourceRequired => selectSourceFirst,
    AppFailure.filesLoad => filesLoadFailed,
    AppFailure.scanSourceRequired => scanSourceRequired,
    AppFailure.scanFailed => scanFailed,
    AppFailure.scrapeFailed => scrapeFailed,
    AppFailure.tmdbAuthentication => tmdbAuthenticationFailed,
    AppFailure.tmdbRateLimited => tmdbRateLimited,
    AppFailure.tmdbTimeout => tmdbTimeout,
    AppFailure.tmdbNetwork => tmdbNetworkFailed,
    AppFailure.tmdbResponse => tmdbResponseFailed,
    AppFailure.contentLoad => contentLoadFailed,
    AppFailure.playbackLink => playbackLinkFailed,
    AppFailure.playbackOpen => playbackOpenFailed,
    AppFailure.playerLaunch => playerLaunchFailed,
  };

  String activity(LibraryActivity activity) => switch (activity.kind) {
    LibraryActivityKind.scanning => scanActivity(activity.completed, activity.total, activity.title),
    LibraryActivityKind.scraping => scrapeActivity(
      activity.completed,
      activity.total,
      activity.success,
      activity.failed,
      activity.title,
    ),
  };
}
