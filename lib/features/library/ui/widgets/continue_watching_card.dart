// 【媒体库界面】展示续播文件及其观看进度并连接播放操作。
// 使用已解析的卡片数据，构建时不逐项补查元数据。

import 'package:flutter/material.dart';
import 'package:mochi_player/features/library/catalog/application/media_card_vo.dart';
import 'package:mochi_player/features/library/ui/library_playback_launcher.dart';
import 'package:mochi_player/features/library/ui/widgets/media_card.dart';
import 'package:mochi_player/l10n/l10n.dart';

class ContinueWatchingCard extends StatelessWidget {
  final MediaCardVO item;

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
      onTap: () => LibraryPlaybackLauncher.playFile(context, item.file, contextTitle: item.playbackContextTitle),
    );
  }
}
