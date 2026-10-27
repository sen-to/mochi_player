import 'package:flutter/material.dart';
import 'package:mochi_player/features/library/catalog/media_card_view_data.dart';
import 'package:mochi_player/features/library/widgets/media_card.dart';
import 'package:mochi_player/features/playback/presentation/playback_launcher.dart';
import 'package:mochi_player/l10n/l10n.dart';

class ContinueWatchingCard extends StatelessWidget {
  final MediaCardViewData item;

  const ContinueWatchingCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return MediaCard(
      title: item.title,
      subtitle: item.file.parsedSeason != null && item.file.parsedEpisode != null
          ? context.l10n.seasonEpisodeLabel(item.file.parsedSeason!, item.file.parsedEpisode!)
          : item.subtitle,
      imageUrl: item.imageUrl,
      rating: item.rating,
      artworkType: MediaArtworkType.backdrop,
      progress: item.file.progress,
      onTap: () => PlaybackLauncher.playFile(context, item.file, contextTitle: item.playbackContextTitle),
    );
  }
}
