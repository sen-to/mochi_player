import 'package:flutter/material.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/library/browser/file_browser_provider.dart';
import 'package:mochi_player/l10n/l10n.dart';

class FileBrowserToolbar extends StatelessWidget {
  final String? sourceName;
  final IconData? sourceIcon;
  final String currentPath;
  final bool canGoBack;
  final FileBrowserViewMode viewMode;
  final FileSortField sortField;
  final bool sortAscending;
  final VoidCallback onBack;
  final ValueChanged<String> onPathSelected;
  final void Function(FileSortField field, bool ascending) onSortChanged;
  final ValueChanged<FileBrowserViewMode> onViewModeChanged;
  final VoidCallback onRefresh;
  final VoidCallback? onRootSelected;
  final bool showDirectoryControls;

  const FileBrowserToolbar({
    super.key,
    this.sourceName,
    this.sourceIcon,
    required this.currentPath,
    required this.canGoBack,
    required this.viewMode,
    required this.sortField,
    required this.sortAscending,
    required this.onBack,
    required this.onPathSelected,
    required this.onSortChanged,
    required this.onViewModeChanged,
    required this.onRefresh,
    this.onRootSelected,
    this.showDirectoryControls = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ToolbarGroup(
          children: [
            _ToolbarIconButton(
              icon: AppIcons.back,
              tooltip: context.l10n.browserBack,
              onPressed: canGoBack ? onBack : null,
            ),
          ],
        ),
        const SizedBox(width: AppSpacing.compact),
        Expanded(
          child: _FilePathBreadcrumb(
            sourceName: sourceName,
            sourceIcon: sourceIcon,
            path: currentPath,
            onRootSelected: onRootSelected,
            onPathSelected: onPathSelected,
          ),
        ),
        if (showDirectoryControls) ...[
          const SizedBox(width: AppSpacing.md),
          _FileSortButton(field: sortField, ascending: sortAscending, onChanged: onSortChanged),
          const SizedBox(width: AppSpacing.compact),
          SizedBox(
            width: _viewModeControlWidth,
            child: AppSegmentedControl<FileBrowserViewMode>(
              value: viewMode,
              onChanged: onViewModeChanged,
              appearance: AppSegmentedControlAppearance.toolbar,
              options: [
                AppSegmentedOption.icon(
                  value: FileBrowserViewMode.list,
                  label: context.l10n.listView,
                  icon: AppIcons.list,
                ),
                AppSegmentedOption.icon(
                  value: FileBrowserViewMode.grid,
                  label: context.l10n.gridView,
                  icon: AppIcons.grid,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(width: AppSpacing.compact),
        _ToolbarGroup(
          children: [
            _ToolbarIconButton(icon: AppIcons.refresh, tooltip: context.l10n.refreshFolder, onPressed: onRefresh),
          ],
        ),
      ],
    );
  }
}

class _FilePathBreadcrumb extends StatelessWidget {
  final String? sourceName;
  final IconData? sourceIcon;
  final String path;
  final VoidCallback? onRootSelected;
  final ValueChanged<String> onPathSelected;

  const _FilePathBreadcrumb({
    required this.sourceName,
    required this.sourceIcon,
    required this.path,
    required this.onRootSelected,
    required this.onPathSelected,
  });

  @override
  Widget build(BuildContext context) {
    final segments = path.split('/').where((segment) => segment.isNotEmpty);
    final crumbs = <({String label, String? path})>[
      (label: context.l10n.rootFolder, path: null),
      if (sourceName != null) (label: sourceName!, path: '/'),
    ];
    var accumulatedPath = '/';
    for (final segment in segments) {
      accumulatedPath = '$accumulatedPath$segment/';
      crumbs.add((label: segment, path: accumulatedPath));
    }

    return SizedBox(
      height: 34,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppRadii.control),
          border: Border.all(color: AppColors.separator(context)),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          scrollDirection: Axis.horizontal,
          itemCount: crumbs.length,
          separatorBuilder: (context, index) => Center(
            child: Text('/', style: TextStyle(fontSize: 13, color: AppColors.textSecondary(context).withAlpha(120))),
          ),
          itemBuilder: (context, index) {
            final crumb = crumbs[index];
            final current = index == crumbs.length - 1;
            final onTap = index == 0
                ? onRootSelected
                : current || crumb.path == null
                ? null
                : () => onPathSelected(crumb.path!);
            return AppClickableArea(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadii.small),
              padding: const EdgeInsets.symmetric(horizontal: 7),
              hoverColor: Colors.transparent,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (sourceName != null && index == 1) ...[
                      Icon(
                        sourceIcon ?? Icons.dns_outlined,
                        size: 15,
                        color: current ? AppColors.textPrimary(context) : AppColors.textSecondary(context),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Text(
                      crumb.label,
                      style: TextStyle(
                        color: current ? AppColors.textPrimary(context) : AppColors.textSecondary(context),
                        fontSize: 13,
                        fontWeight: current ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FileSortButton extends StatelessWidget {
  final FileSortField field;
  final bool ascending;
  final void Function(FileSortField field, bool ascending) onChanged;

  const _FileSortButton({required this.field, required this.ascending, required this.onChanged});

  String _label(BuildContext context) => switch (field) {
    FileSortField.name => context.l10n.name,
    FileSortField.size => context.l10n.size,
    FileSortField.modifiedAt => context.l10n.modifiedAt,
  };

  String _directionLabel(BuildContext context) => ascending ? context.l10n.ascending : context.l10n.descending;

  @override
  Widget build(BuildContext context) {
    return _ToolbarGroup(
      children: [
        AppDropdown<FileSortField>(
          trigger: SizedBox(
            height: 34,
            child: Padding(
              padding: const EdgeInsets.only(left: 9, right: 7),
              child: Row(
                children: [
                  Icon(
                    ascending ? AppIcons.ascending : AppIcons.descending,
                    size: 15,
                    color: AppColors.textSecondary(context),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    _label(context),
                    style: TextStyle(color: AppColors.textPrimary(context), fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 5),
                  const Icon(AppIcons.chevronDown, size: 13),
                ],
              ),
            ),
          ),
          tooltip: context.l10n.sortDescription(_label(context), _directionLabel(context)),
          selectedValue: field,
          onSelected: (value) => onChanged(value, value == field ? !ascending : true),
          options: [
            AppDropdownOption(value: FileSortField.name, label: context.l10n.name),
            AppDropdownOption(value: FileSortField.size, label: context.l10n.size),
            AppDropdownOption(value: FileSortField.modifiedAt, label: context.l10n.modifiedAt),
          ],
          menuWidth: 126,
        ),
      ],
    );
  }
}

class _ToolbarGroup extends StatelessWidget {
  const _ToolbarGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _toolbarHeight,
      decoration: BoxDecoration(
        color: AppColors.controlSurface(context),
        borderRadius: BorderRadius.circular(AppRadii.surface),
        border: Border.all(color: AppColors.separator(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index != 0)
              SizedBox(
                width: 1,
                height: _toolbarHeight,
                child: ColoredBox(color: AppColors.separator(context)),
              ),
            children[index],
          ],
        ],
      ),
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  const _ToolbarIconButton({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: AppClickableArea(
        onTap: onPressed,
        width: _toolbarButtonWidth,
        height: _toolbarHeight,
        borderRadius: BorderRadius.zero,
        backgroundColor: Colors.transparent,
        hoverColor: AppColors.hoverSurface(context),
        child: Icon(
          icon,
          size: 18,
          color: onPressed == null ? AppColors.textSecondary(context).withAlpha(90) : AppColors.textPrimary(context),
        ),
      ),
    );
  }
}

const double _toolbarHeight = 34;
const double _toolbarButtonWidth = 36;
const double _viewModeControlWidth = 74;
