// 【媒体库界面】复用通用标签展示媒体评分。
// 只负责评分样式，不保存状态。

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:mochi_player/core/ui/components/data_display/app_tag.dart';
import 'package:mochi_player/core/ui/theme/app_colors.dart';
import 'package:mochi_player/l10n/l10n.dart';

/// 复用通用标签组件，应用媒体评分样式。
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
