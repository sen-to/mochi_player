import 'package:flutter/material.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/features/library/presentation/pages/media_detail_page.dart';
import 'package:mochi_player/features/library/presentation/widgets/media_card.dart';
import 'package:mochi_player/l10n/l10n.dart';

class LibraryItemPosterCard extends StatelessWidget {
  final LibraryItem item;
  final MediaArtworkType artworkType;
  final VoidCallback? onTap;

  const LibraryItemPosterCard({super.key, required this.item, this.artworkType = MediaArtworkType.poster, this.onTap});

  @override
  Widget build(BuildContext context) {
    return MediaCard(
      title: item.title,
      subtitle: _subtitle(context, item),
      imageUrl: artworkType == MediaArtworkType.backdrop ? item.backdropUrl : item.posterUrl,
      rating: item.rating,
      artworkType: artworkType,
      onTap: onTap ?? () => openMediaDetailPage(context, item),
    );
  }

  String? _subtitle(BuildContext context, LibraryItem item) {
    if (item is TVShow) {
      final localSeasonCount = item.seasons.length;
      if (localSeasonCount > 0) {
        return context.l10n.totalSeasonCount(localSeasonCount);
      }
    }
    return item.releaseYear?.toString();
  }
}
