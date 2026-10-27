import 'package:mochi_player/core/domain/media/models.dart';

/// Fully resolved data needed to render a media file card.
///
/// Widgets consume this object directly instead of querying metadata while
/// building the UI.
class MediaCardViewData {
  final MediaFile file;
  final LibraryItem? libraryItem;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final double rating;
  final String? playbackContextTitle;

  const MediaCardViewData({
    required this.file,
    required this.title,
    this.libraryItem,
    this.subtitle,
    this.imageUrl,
    this.rating = 0,
    this.playbackContextTitle,
  });
}
