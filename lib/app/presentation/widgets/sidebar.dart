import 'package:flutter/material.dart';
import 'package:mochi_player/app/presentation/navigation/app_destination.dart';
import 'package:mochi_player/core/platform/window_service.dart';
import 'package:mochi_player/core/ui/components/basic/app_clickable_area.dart';
import 'package:mochi_player/core/ui/theme/app_colors.dart';
import 'package:mochi_player/l10n/l10n.dart';

class _SidebarMetrics {
  const _SidebarMetrics._();

  static const width = 224.0;

  // Windows caption buttons live on the far right; this remains a compact,
  // platform-neutral drag strip rather than a faux left-side title bar.
  static const topDragAreaHeight = 40.0;
  static const horizontalInset = 16.0;
  static const sectionGap = 16.0;
  static const itemHeight = 36.0;
  static const itemVerticalGap = 1.0;
  static const itemHorizontalPadding = 12.0;
  static const itemRadius = 8.0;
  static const itemIconSize = 17.0;
  static const itemIconLabelGap = 10.0;
}

class Sidebar extends StatelessWidget {
  final AppDestination selectedDestination;
  final ValueChanged<AppDestination> onDestinationSelected;

  const Sidebar({super.key, required this.selectedDestination, required this.onDestinationSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: _SidebarMetrics.width,
      decoration: BoxDecoration(
        color: AppColors.sidebarBackground(context),
        border: Border(
          right: BorderSide(color: theme.dividerColor, width: 1), // 使用主题分割线颜色
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (theme.platform != TargetPlatform.windows)
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (_) => WindowService.instance.startDragging(),
              child: const SizedBox(height: _SidebarMetrics.topDragAreaHeight, width: double.infinity),
            ),

          _buildSectionTitle(context.l10n.library, context),
          _buildGroup([AppDestination.home, AppDestination.movies, AppDestination.series]),

          const SizedBox(height: _SidebarMetrics.sectionGap),

          _buildSectionTitle(context.l10n.sources, context),
          _buildGroup([AppDestination.fileBrowser]),

          const SizedBox(height: _SidebarMetrics.sectionGap),

          _buildSectionTitle(context.l10n.lists, context),
          _buildGroup([AppDestination.favorites]),

          const Spacer(),
          Divider(height: 1, color: theme.dividerColor),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _SidebarMetrics.horizontalInset),
            child: _SidebarItem(
              destination: AppDestination.settings,
              selectedDestination: selectedDestination,
              onTap: onDestinationSelected,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 7),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).textTheme.titleMedium?.color?.withAlpha((255 * 0.6).round()),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
  }

  Widget _buildGroup(List<AppDestination> destinations) {
    return Column(
      children: destinations.map((destination) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _SidebarMetrics.horizontalInset,
            vertical: _SidebarMetrics.itemVerticalGap,
          ),
          child: _SidebarItem(
            destination: destination,
            selectedDestination: selectedDestination,
            onTap: onDestinationSelected,
          ),
        );
      }).toList(),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final AppDestination destination;
  final AppDestination selectedDestination;
  final ValueChanged<AppDestination> onTap;

  const _SidebarItem({required this.destination, required this.selectedDestination, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = selectedDestination == destination;
    final primary = AppColors.primary(context);
    final selectedBackground = AppColors.selectedSurface(context);
    final restingForeground = theme.textTheme.titleMedium!.color!;
    final foregroundColor = isSelected ? primary : restingForeground;

    return AppClickableArea(
      onTap: () => onTap(destination),
      height: _SidebarMetrics.itemHeight,
      padding: const EdgeInsets.symmetric(horizontal: _SidebarMetrics.itemHorizontalPadding),
      borderRadius: BorderRadius.circular(_SidebarMetrics.itemRadius),
      backgroundColor: isSelected ? selectedBackground : Colors.transparent,
      hoverColor: isSelected ? Colors.transparent : AppColors.hoverSurface(context),
      child: Row(
        children: [
          Icon(destination.icon, size: _SidebarMetrics.itemIconSize, color: foregroundColor),
          const SizedBox(width: _SidebarMetrics.itemIconLabelGap),
          Text(
            destination.title(context),
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}
