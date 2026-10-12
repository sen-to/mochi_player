import 'package:flutter/material.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/library/domain/file_browser_entry.dart';
import 'package:mochi_player/features/library/presentation/widgets/file_browser_list_row.dart';
import 'package:mochi_player/l10n/l10n.dart';

class FileBrowserList extends StatelessWidget {
  static const double headerHeight = 47;
  static const double rowHeight = 64;
  static const double dividerHeight = 1;
  static const double borderWidth = 1;

  final List<FileBrowserEntry> items;
  final ValueChanged<FileBrowserEntry> onItemTap;
  final PageStorageKey<String> scrollStorageKey;

  const FileBrowserList({super.key, required this.items, required this.onItemTap, required this.scrollStorageKey});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.separator(context), width: borderWidth),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const _FileListHeader(),
          Divider(height: 1, color: AppColors.separator(context)),
          Expanded(
            child: ListView.separated(
              key: scrollStorageKey,
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                indent: AppSpacing.xl,
                endIndent: AppSpacing.xl,
                color: AppColors.separator(context),
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return SizedBox(
                  height: rowHeight,
                  child: FileBrowserListRow(
                    item: item,
                    onTap: item.isDirectory || item.isPlayable ? () => onItemTap(item) : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FileBrowserListSection extends StatelessWidget {
  static const double _summarySpace = 34;
  static const double _minimumListHeight = _summarySpace + FileBrowserList.headerHeight;

  final List<FileBrowserEntry> items;
  final int totalItemCount;
  final bool isFiltered;
  final ValueChanged<FileBrowserEntry> onItemTap;
  final PageStorageKey<String> scrollStorageKey;

  const FileBrowserListSection({
    super.key,
    required this.items,
    required this.totalItemCount,
    required this.isFiltered,
    required this.onItemTap,
    required this.scrollStorageKey,
  });

  @override
  Widget build(BuildContext context) {
    final naturalHeight =
        FileBrowserList.headerHeight +
        2 * FileBrowserList.borderWidth +
        FileBrowserList.dividerHeight +
        items.length * FileBrowserList.rowHeight +
        (items.length - 1).clamp(0, items.length).toDouble() * FileBrowserList.dividerHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight < _summarySpace) {
          return const SizedBox.shrink();
        }
        if (constraints.maxHeight < _minimumListHeight) {
          return FileBrowserSummary(items: items, totalItemCount: totalItemCount, isFiltered: isFiltered);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: SizedBox(
                height: naturalHeight,
                child: FileBrowserList(items: items, onItemTap: onItemTap, scrollStorageKey: scrollStorageKey),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FileBrowserSummary(items: items, totalItemCount: totalItemCount, isFiltered: isFiltered),
          ],
        );
      },
    );
  }
}

class _FileListHeader extends StatelessWidget {
  const _FileListHeader();

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary(context));
    return SizedBox(
      height: FileBrowserList.headerHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Row(
          children: [
            Expanded(flex: 5, child: Text(context.l10n.name, style: style)),
            const SizedBox(width: 52),
            SizedBox(width: 120, child: Text(context.l10n.size, style: style)),
            Expanded(flex: 2, child: Text(context.l10n.modifiedAt, style: style)),
            const SizedBox(width: 54),
          ],
        ),
      ),
    );
  }
}

class FileBrowserSummary extends StatelessWidget {
  final List<FileBrowserEntry> items;
  final int totalItemCount;
  final bool isFiltered;

  const FileBrowserSummary({super.key, required this.items, required this.totalItemCount, required this.isFiltered});

  @override
  Widget build(BuildContext context) {
    final folderCount = items.where((item) => item.isDirectory).length;
    final fileCount = items.length - folderCount;
    final parts = <String>[
      if (folderCount > 0) context.l10n.folderCount(folderCount),
      if (fileCount > 0) context.l10n.fileCount(fileCount),
      if (items.isEmpty) context.l10n.zeroItems,
    ];
    final summary = parts.join(' · ');
    return Text(
      isFiltered ? context.l10n.filteredDirectorySummary(summary, totalItemCount) : summary,
      style: TextStyle(fontSize: 13, color: AppColors.textSecondary(context)),
    );
  }
}
