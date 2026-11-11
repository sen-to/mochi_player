// 【目录界面】展示电影或剧集的结果数量、筛选和排序入口。
// 电影和剧集共用触发控件与即时筛选弹窗，目录页面接收选择并发起查询。

import 'package:flutter/material.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/library/catalog/application/library_catalog_repository.dart';
import 'package:mochi_player/features/library/catalog/domain/library_title_filter.dart';
import 'package:mochi_player/l10n/l10n.dart';

class LibraryCatalogToolbar extends StatefulWidget {
  const LibraryCatalogToolbar({
    super.key,
    required this.kind,
    required this.summary,
    required this.filter,
    required this.sort,
    required this.onFilter,
    required this.onSort,
  });

  final LibraryTitleKind kind;
  final LibraryTitleCatalogSummary? summary;
  final LibraryTitleFilter filter;
  final LibraryTitleSort sort;
  final ValueChanged<LibraryTitleFilter> onFilter;
  final ValueChanged<LibraryTitleSort> onSort;

  @override
  State<LibraryCatalogToolbar> createState() => _LibraryCatalogToolbarState();
}

class _LibraryCatalogToolbarState extends State<LibraryCatalogToolbar> {
  final _filterMenu = MenuController();
  final _sortMenu = MenuController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!TickerMode.of(context)) {
      if (_filterMenu.isOpen) _filterMenu.close();
      if (_sortMenu.isOpen) _sortMenu.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.summary?.count;
    final kind = widget.kind;
    final filter = widget.filter;
    final summary = widget.summary;
    final sort = widget.sort;
    final l10n = context.l10n;
    final sortOptions = [
      AppDropdownOption(value: LibraryTitleSort.latestAdded, label: l10n.recentlyAdded),
      AppDropdownOption(value: LibraryTitleSort.releaseYear, label: l10n.catalogReleaseYear),
      AppDropdownOption(value: LibraryTitleSort.rating, label: l10n.catalogRating),
      AppDropdownOption(value: LibraryTitleSort.title, label: l10n.catalogTitle),
    ];
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        child: Row(
          children: [
            Expanded(
              child: Text(
                count == null
                    ? ''
                    : kind == LibraryTitleKind.movie
                    ? l10n.catalogMovieCount(count)
                    : l10n.catalogSeriesCount(count),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textSecondary(context), fontSize: 13),
              ),
            ),
            MenuAnchor(
              controller: _filterMenu,
              // 分区页面位于独立导航浮层内，菜单与锚点使用同一浮层坐标系。
              useRootOverlay: false,
              consumeOutsideTap: true,
              alignmentOffset: const Offset(-360, 6),
              reservedPadding: const EdgeInsets.all(16),
              style: AppMenuSurface.style(
                context,
                padding: EdgeInsets.zero,
              ).copyWith(alignment: AlignmentDirectional.bottomEnd),
              menuChildren: [
                Focus(
                  autofocus: true,
                  child: _LibraryFilterDialog(
                    kind: kind,
                    filter: filter,
                    genres: summary?.genres ?? const [],
                    decades: summary?.decades ?? const [],
                    onApply: widget.onFilter,
                  ),
                ),
              ],
              builder: (context, controller, child) => _CatalogControl(
                label: l10n.catalogFilter,
                icon: Icons.tune_rounded,
                selected: filter.count > 0,
                onTap: () => controller.isOpen ? controller.close() : controller.open(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppDropdown<LibraryTitleSort>(
              controller: _sortMenu,
              selectedValue: sort,
              options: sortOptions,
              onSelected: widget.onSort,
              menuWidth: 132,
              menuAlignment: AppDropdownMenuAlignment.end,
              triggerBuilder: (_, toggle) => _CatalogControl(
                label: sortOptions.firstWhere((option) => option.value == sort).label,
                icon: Icons.swap_vert_rounded,
                dropdown: true,
                onTap: toggle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _controlBorder(BuildContext context) => AppColors.separator(context).withAlpha(140);

class _CatalogControl extends StatelessWidget {
  const _CatalogControl({
    required this.label,
    required this.onTap,
    this.icon,
    this.dropdown = false,
    this.plain = false,
    this.selected = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool dropdown;
  final bool plain;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final secondary = AppColors.textSecondary(context);
    final accent = AppColors.primary(context);
    return AppClickableArea(
      onTap: onTap,
      hoverDuration: AppControlMetrics.stateAnimationDuration,
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      borderRadius: AppDropdown.triggerRadius,
      backgroundColor: plain
          ? Colors.transparent
          : selected
          ? AppColors.selectedSurface(context)
          : AppColors.controlSurface(context),
      borderColor: plain ? null : (selected ? accent.withAlpha(140) : _controlBorder(context)),
      hoverColor: AppColors.hoverSurface(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: selected ? accent : secondary), const SizedBox(width: 5)],
          Text(
            label,
            style: TextStyle(
              color: plain
                  ? (onTap == null ? secondary : accent)
                  : (selected ? accent : AppColors.textPrimary(context)),
              fontSize: 12,
            ),
          ),
          if (dropdown) ...[const SizedBox(width: 5), Icon(AppIcons.chevronDown, size: 11, color: secondary)],
        ],
      ),
    );
  }
}

class _LibraryFilterDialog extends StatefulWidget {
  const _LibraryFilterDialog({
    required this.kind,
    required this.filter,
    required this.genres,
    required this.decades,
    required this.onApply,
  });

  final LibraryTitleKind kind;
  final LibraryTitleFilter filter;
  final List<String> genres;
  final List<int> decades;
  final ValueChanged<LibraryTitleFilter> onApply;

  @override
  State<_LibraryFilterDialog> createState() => _LibraryFilterDialogState();
}

class _LibraryFilterDialogState extends State<_LibraryFilterDialog> {
  late Set<String> _genres = {...widget.filter.genres};
  late int? _decade = widget.filter.decade;
  bool _showAllGenres = false;

  LibraryTitleFilter get _selection => LibraryTitleFilter(genres: Set.unmodifiable(_genres), decade: _decade);

  void _change(VoidCallback change) {
    setState(change);
    widget.onApply(_selection);
  }

  void _reset() {
    _change(() {
      _genres.clear();
      _decade = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final draft = _selection;
    const sectionGap = 12.0;
    final theme = Theme.of(context);
    final labelStyle = TextStyle(fontSize: 12, color: AppColors.textSecondary(context));
    final chipTheme = ChipTheme.of(context);
    final tightChipTheme = chipTheme.copyWith(
      labelStyle: TextStyle(fontSize: 11, color: AppColors.textPrimary(context)),
      side: BorderSide(color: _controlBorder(context)),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      labelPadding: const EdgeInsets.symmetric(horizontal: 3),
      elevation: 0,
      pressElevation: 0,
    );
    final genres = {...widget.genres, ..._genres}.toList();
    final visibleGenres = _showAllGenres ? genres : [...genres.take(8), ...genres.skip(8).where(_genres.contains)];
    final decades = {...widget.decades, ?_decade}.toList()..sort((a, b) => b.compareTo(a));
    final viewport = MediaQuery.sizeOf(context);
    final accent = AppColors.primary(context);
    return SizedBox(
      width: (viewport.width - 32).clamp(0.0, 360.0).toDouble(),
      child: Theme(
        data: theme.copyWith(splashFactory: NoSplash.splashFactory, highlightColor: Colors.transparent),
        child: ChipTheme(
          data: tightChipTheme,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: (viewport.height - 124).clamp(160.0, 560.0).toDouble()),
            child: SingleChildScrollView(
              primary: false,
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.kind == LibraryTitleKind.movie ? l10n.catalogFilterMovies : l10n.catalogFilterSeries,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                      _CatalogControl(label: l10n.catalogReset, plain: true, onTap: draft.count == 0 ? null : _reset),
                    ],
                  ),
                  SizedBox(height: sectionGap),
                  if (genres.isNotEmpty) ...[
                    Text(l10n.catalogGenres, style: labelStyle),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: 4,
                      children: [
                        for (final genre in visibleGenres)
                          FilterChip(
                            label: Text(genre),
                            selected: _genres.contains(genre),
                            selectedColor: AppColors.selectedSurface(context),
                            checkmarkColor: accent,
                            showCheckmark: false,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: const VisualDensity(vertical: -2),
                            onSelected: (selected) => _change(() {
                              if (selected) {
                                _genres.add(genre);
                              } else {
                                _genres.remove(genre);
                              }
                            }),
                          ),
                        if (!_showAllGenres && visibleGenres.length < genres.length)
                          ActionChip(
                            label: const Icon(Icons.more_horiz_rounded, size: 18),
                            tooltip: l10n.catalogMoreGenres,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: const VisualDensity(vertical: -2),
                            onPressed: () => setState(() => _showAllGenres = true),
                          ),
                      ],
                    ),
                    SizedBox(height: sectionGap),
                  ],
                  Row(
                    children: [
                      Expanded(child: Text(l10n.catalogReleaseYear, style: labelStyle)),
                      AppDropdown<int?>(
                        selectedValue: _decade,
                        menuWidth: 200,
                        menuAlignment: AppDropdownMenuAlignment.end,
                        options: [
                          AppDropdownOption(value: null, label: l10n.catalogAnyYear),
                          for (final decade in decades)
                            AppDropdownOption(value: decade, label: '$decade – ${decade + 9}'),
                        ],
                        onSelected: (value) => _change(() => _decade = value),
                        triggerBuilder: (_, toggle) => _CatalogControl(
                          label: _decade == null ? l10n.catalogAnyYear : '$_decade – ${_decade! + 9}',
                          dropdown: true,
                          onTap: toggle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
