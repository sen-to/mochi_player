import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mochi_player/core/ui/components/basic/app_clickable_area.dart';
import 'package:mochi_player/core/ui/components/overlay/app_dropdown.dart';
import 'package:mochi_player/core/ui/theme/app_colors.dart';
import 'package:mochi_player/core/ui/theme/app_icons.dart';
import 'package:mochi_player/core/ui/theme/app_spacing.dart';
import 'package:mochi_player/features/library/browser/file_browser_entry.dart';
import 'package:mochi_player/features/library/browser/file_browser_entry_display.dart';
import 'package:mochi_player/l10n/l10n.dart';

class FileBrowserListRow extends StatelessWidget {
  final FileBrowserEntry item;
  final VoidCallback? onTap;

  const FileBrowserListRow({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppClickableArea(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      hoverColor: AppColors.hoverSurface(context),
      child: Row(
        children: [
          Icon(item.browserIcon, color: item.browserIconColor(context), size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 5,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.textTheme.bodyMedium!.color),
                ),
                const SizedBox(height: 3),
                Text(
                  item.browserTypeLabel(context),
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary(context)),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          SizedBox(
            width: 120,
            child: Text(
              item.isDirectory ? '—' : item.browserSizeLabel(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary(context)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.browserModifiedAtLabel(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary(context)),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          SizedBox(
            width: 38,
            child: AppDropdown<_FileBrowserItemAction>(
              trigger: SizedBox(
                width: 38,
                height: 34,
                child: Icon(AppIcons.more, color: AppColors.textSecondary(context)),
              ),
              tooltip: context.l10n.moreActions,
              menuWidth: 140,
              menuAlignment: AppDropdownMenuAlignment.end,
              onSelected: _handleAction,
              options: [
                if (item.isDirectory || item.isPlayable)
                  AppDropdownOption(
                    value: _FileBrowserItemAction.open,
                    label: item.isDirectory ? context.l10n.open : context.l10n.play,
                  ),
                AppDropdownOption(value: _FileBrowserItemAction.copyPath, label: context.l10n.copyPath),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(_FileBrowserItemAction action) {
    switch (action) {
      case _FileBrowserItemAction.open:
        onTap?.call();
      case _FileBrowserItemAction.copyPath:
        Clipboard.setData(ClipboardData(text: item.path));
    }
  }
}

enum _FileBrowserItemAction { open, copyPath }
