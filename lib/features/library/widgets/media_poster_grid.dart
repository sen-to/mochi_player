import 'package:flutter/material.dart';
import 'package:mochi_player/core/ui/theme/app_spacing.dart';

/// Responsive media-poster grid shared by library and search result pages.
class MediaPosterGrid<T> extends StatelessWidget {
  const MediaPosterGrid({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.storageKey,
    this.controller,
    this.topPadding = 100,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String storageKey;
  final ScrollController? controller;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth - AppSpacing.page * 2;
        const desiredItemWidth = 180.0;
        final calculatedCount = (contentWidth / desiredItemWidth).round();
        final crossAxisCount = calculatedCount < 3 ? 3 : calculatedCount;

        return GridView.builder(
          key: PageStorageKey<String>(storageKey),
          controller: controller,
          padding: EdgeInsets.fromLTRB(AppSpacing.page, topPadding, AppSpacing.page, AppSpacing.page),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.57,
            crossAxisSpacing: 24,
            mainAxisSpacing: 32,
          ),
          itemBuilder: (context, index) => itemBuilder(context, items[index]),
        );
      },
    );
  }
}
