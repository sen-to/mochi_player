import 'package:flutter/widgets.dart';
import 'package:mochi_player/core/domain/app_failure.dart';
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
