import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/domain/media/watch_progress_policy.dart';
import 'package:mochi_player/core/formatters/media_format.dart';
import 'package:mochi_player/core/infrastructure/tmdb/tmdb_image_cache_manager.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/library/detail/favorite_button.dart';
import 'package:mochi_player/features/library/detail/media_detail_view_model.dart';
import 'package:mochi_player/features/library/widgets/library_query.dart';
import 'package:mochi_player/features/library/widgets/media_rating_tag.dart';
import 'package:mochi_player/features/library/library_playback_launcher.dart';
import 'package:mochi_player/l10n/l10n.dart';

const double _detailReadableWidth = 820;

class MediaDetailHeader extends StatelessWidget {
  final MediaDetailViewModel viewModel;

  const MediaDetailHeader({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).scaffoldBackgroundColor;

    return RepaintBoundary(
      child: SizedBox(
        height: 320,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildBackdrop(context),
            _buildGradientOverlay(cardColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 30, 40, 28),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 760;
                  if (compact) {
                    return _HeaderContent(viewModel: viewModel, compact: true);
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (viewModel.posterUrl.isNotEmpty) ...[
                        _PosterImage(posterUrl: viewModel.posterUrl),
                        const SizedBox(width: 28),
                      ],
                      Expanded(child: _HeaderContent(viewModel: viewModel)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackdrop(BuildContext context) {
    final imageUrl = viewModel.backdropUrl.isNotEmpty ? viewModel.backdropUrl : viewModel.posterUrl;
    if (imageUrl.isEmpty) {
      return const _FallbackBackdrop();
    }

    return CachedNetworkImage(
      cacheManager: TmdbImageCacheManager.instance,
      imageUrl: imageUrl,
      width: double.infinity,
      height: 320,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      placeholder: (context, url) => const _FallbackBackdrop(),
      errorWidget: (context, url, error) => const _FallbackBackdrop(),
    );
  }

  Widget _buildGradientOverlay(Color cardColor) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.black.withAlpha(120),
                Colors.black.withAlpha(76),
                Colors.black.withAlpha(18),
                Colors.transparent,
              ],
              stops: const [0.0, 0.34, 0.68, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withAlpha(10),
                Colors.black.withAlpha(28),
                Colors.black.withAlpha(78),
                Colors.transparent,
                cardColor.withAlpha(70),
                cardColor.withAlpha(185),
                cardColor,
              ],
              stops: const [0.0, 0.24, 0.52, 0.66, 0.78, 0.92, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

class _FallbackBackdrop extends StatelessWidget {
  const _FallbackBackdrop();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A2D34), Color(0xFF111216)],
        ),
      ),
    );
  }
}

class _HeaderContent extends StatelessWidget {
  final MediaDetailViewModel viewModel;
  final bool compact;

  const _HeaderContent({required this.viewModel, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final logoUrl = viewModel.logoUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (logoUrl != null && logoUrl.isNotEmpty) ...[
          _LogoImage(logoUrl: logoUrl, fallbackTitle: viewModel.title, compact: compact),
          const SizedBox(height: 14),
        ],
        _MetadataStrip(viewModel: viewModel),
        if (logoUrl == null || logoUrl.isEmpty) ...[
          const SizedBox(height: 12),
          _TitleText(title: viewModel.title, compact: compact),
        ],
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _detailReadableWidth),
          child: Text(
            viewModel.overview ?? context.l10n.noOverview,
            maxLines: compact ? 2 : 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withAlpha(225),
              fontSize: 14,
              height: 1.45,
              shadows: const [Shadow(offset: Offset(0, 1), blurRadius: 4, color: Colors.black54)],
            ),
          ),
        ),
        const SizedBox(height: 18),
        _PrimaryActionArea(viewModel: viewModel),
      ],
    );
  }
}

class _PrimaryActionArea extends StatelessWidget {
  final MediaDetailViewModel viewModel;

  const _PrimaryActionArea({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return LibraryQuery<List<MediaFile>>(
      queryKey: (viewModel.item.runtimeType, viewModel.tmdbId),
      query: (r) => r.watchVersions(viewModel.item),
      initialData: const [],
      builder: (context, files) => _ActionRow(viewModel: viewModel, action: _resolvePrimaryAction(context, files)),
    );
  }

  _PrimaryPlayAction _resolvePrimaryAction(BuildContext context, List<MediaFile> files) {
    if (viewModel.isTVShow) {
      final target = EpisodePlaybackTargetResolver.resolveForShowPlayback(files);
      if (target == null) {
        return _PrimaryPlayAction(
          label: context.l10n.unplayable,
          detail: context.l10n.noPlayableEpisodes,
          enabled: false,
        );
      }
      final verb = target.resumesCurrentEpisode ? 'resume' : 'play';
      return _PrimaryPlayAction(
        label: _episodeActionLabel(context, target.file, verb),
        detail: target.resumesCurrentEpisode
            ? _resumeDetail(context, target.file)
            : _episodeCountDetail(context, files),
        onPressed: () => LibraryPlaybackLauncher.playFile(context, target.file, contextTitle: viewModel.title),
      );
    }

    final resumeFile = _latestResumeFile(files);

    if (resumeFile != null) {
      return _PrimaryPlayAction(
        label: context.l10n.resumePlayback,
        detail: _resumeDetail(context, resumeFile),
        onPressed: () => LibraryPlaybackLauncher.playFile(context, resumeFile),
      );
    }

    final movie = viewModel.movie;
    if (movie != null) {
      return _PrimaryPlayAction(
        label: context.l10n.play,
        enabled: files.isNotEmpty,
        onPressed: files.isEmpty ? null : () => LibraryPlaybackLauncher.playMovie(context, movie),
      );
    }

    return _PrimaryPlayAction(label: context.l10n.unplayable, enabled: false);
  }

  MediaFile? _latestResumeFile(List<MediaFile> files) {
    final candidates = files
        .where(
          (file) => file.position > 0 && file.progress > 0 && file.progress < WatchProgressPolicy.completionThreshold,
        )
        .toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => (b.lastWatchedAt ?? DateTime(0)).compareTo(a.lastWatchedAt ?? DateTime(0)));
    return candidates.first;
  }

  String _episodeActionLabel(BuildContext context, MediaFile file, String verb) {
    final episode = file.parsedEpisode;
    if (episode != null) return context.l10n.episodeAction(verb, episode);

    return context.l10n.episodeActionUnknown(verb);
  }

  String _resumeDetail(BuildContext context, MediaFile file) {
    if (file.duration <= 0) return context.l10n.resumeLastPosition;
    return context.l10n.resumeFrom(MediaFormat.clockDuration(Duration(milliseconds: file.position)));
  }

  String _episodeCountDetail(BuildContext context, List<MediaFile> files) {
    final count = files.where((file) => file.mediaType == MediaType.episode).length;
    return context.l10n.playableEpisodeCount(count);
  }
}

class _MetadataStrip extends StatelessWidget {
  final MediaDetailViewModel viewModel;

  const _MetadataStrip({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    if (viewModel.rating > 0) {
      items.add(MediaRatingTag(rating: viewModel.rating));
    }
    if (viewModel.releaseYear != null) {
      items.add(AppTag(text: '${viewModel.releaseYear}', appearance: AppAppearance.overlay));
    }
    final certification = viewModel.certification;
    if (certification != null && certification.isNotEmpty) {
      items.add(AppTag(text: certification, appearance: AppAppearance.overlay));
    }
    if (viewModel.isTVShow) {
      final totalSeasonCount = viewModel.totalSeasonCount;
      if (totalSeasonCount != null && totalSeasonCount > 0) {
        items.add(AppTag(text: context.l10n.totalSeasonCount(totalSeasonCount), appearance: AppAppearance.overlay));
      }
    }
    items.addAll(viewModel.genres.take(3).map((genre) => AppTag(text: genre, appearance: AppAppearance.overlay)));

    return Wrap(spacing: 8, runSpacing: 8, children: items);
  }
}

class _ActionRow extends StatelessWidget {
  final MediaDetailViewModel viewModel;
  final _PrimaryPlayAction action;

  const _ActionRow({required this.viewModel, required this.action});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        AppButton(
          onPressed: action.enabled ? action.onPressed : null,
          icon: Icons.play_arrow_rounded,
          label: action.label,
          size: AppButtonSize.regular,
        ),
        FavoriteButton(item: viewModel.item, overrideColor: Colors.white, showLabel: true),
        if (action.detail != null)
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              action.detail!,
              style: TextStyle(color: Colors.white.withAlpha(205), fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }
}

class _PosterImage extends StatelessWidget {
  final String posterUrl;

  const _PosterImage({required this.posterUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 150,
        height: 225,
        child: posterUrl.isNotEmpty
            ? CachedNetworkImage(
                cacheManager: TmdbImageCacheManager.instance,
                imageUrl: posterUrl,
                width: 150,
                height: 225,
                fit: BoxFit.cover,
                placeholder: (context, url) => _placeholder(),
                errorWidget: (context, url, error) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.white.withAlpha(24),
      child: const Icon(Icons.movie_rounded, color: Colors.white54, size: 44),
    );
  }
}

class _LogoImage extends StatelessWidget {
  final String logoUrl;
  final String fallbackTitle;
  final bool compact;

  const _LogoImage({required this.logoUrl, required this.fallbackTitle, required this.compact});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 260,
          height: 62,
          child: CachedNetworkImage(
            cacheManager: TmdbImageCacheManager.instance,
            imageUrl: logoUrl,
            width: 260,
            height: 62,
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            placeholder: (context, url) => const SizedBox.expand(),
            errorWidget: (context, url, error) => _TitleText(title: fallbackTitle, compact: compact),
          ),
        ),
      ),
    );
  }
}

class _TitleText extends StatelessWidget {
  final String title;
  final bool compact;

  const _TitleText({required this.title, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.white,
        fontSize: compact ? 30 : 36,
        fontWeight: FontWeight.w800,
        height: 1.08,
        shadows: const [Shadow(offset: Offset(0, 2), blurRadius: 10, color: Colors.black54)],
      ),
    );
  }
}

class _PrimaryPlayAction {
  final String label;
  final String? detail;
  final VoidCallback? onPressed;
  final bool enabled;

  const _PrimaryPlayAction({required this.label, this.detail, this.onPressed, this.enabled = true});
}
