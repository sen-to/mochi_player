import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:mochi_player/core/ui/components/data_display/app_tag.dart';
import 'package:mochi_player/core/ui/theme/app_colors.dart';
import 'package:mochi_player/l10n/l10n.dart';

/// Applies the media rating style while reusing the shared tag component.
class MediaRatingTag extends StatelessWidget {
  const MediaRatingTag({super.key, required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return AppTag(
      text: NumberFormat('0.0', context.l10n.localeName).format(rating),
      icon: Icons.star_rounded,
      backgroundColor: AppColors.rating,
      foregroundColor: Colors.black.withAlpha(220),
      outlined: false,
    );
  }
}
