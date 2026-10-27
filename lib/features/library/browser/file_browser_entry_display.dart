import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mochi_player/features/library/media_file_kind.dart';
import 'package:mochi_player/core/formatters/media_format.dart';
import 'package:mochi_player/core/ui/theme/app_colors.dart';
import 'package:mochi_player/core/ui/theme/app_icons.dart';
import 'package:mochi_player/features/library/browser/file_browser_entry.dart';
import 'package:mochi_player/l10n/l10n.dart';

extension FileBrowserEntryDisplay on FileBrowserEntry {
  IconData get browserIcon => switch (kind) {
    MediaFileKind.directory => AppIcons.folder,
    MediaFileKind.video => AppIcons.video,
    MediaFileKind.other => AppIcons.file,
  };

  String browserTypeLabel(BuildContext context) => switch (kind) {
    MediaFileKind.directory => context.l10n.folder,
    MediaFileKind.video => context.l10n.video,
    MediaFileKind.other => context.l10n.file,
  };

  String browserSizeLabel(BuildContext context) =>
      isDirectory ? '' : MediaFormat.fileSize(size, locale: context.l10n.localeName);

  String browserModifiedAtLabel(BuildContext context) =>
      modifiedAt == null ? '—' : DateFormat.yMd(context.l10n.localeName).add_Hm().format(modifiedAt!);

  Color browserIconColor(BuildContext context) {
    return switch (kind) {
      MediaFileKind.video => Theme.of(context).colorScheme.primary,
      MediaFileKind.directory || MediaFileKind.other => AppColors.textSecondary(context),
    };
  }
}
