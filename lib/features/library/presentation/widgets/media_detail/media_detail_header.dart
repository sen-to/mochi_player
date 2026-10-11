import 'package:mochi_player/features/library/presentation/widgets/library_query.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/formatters/media_format.dart';
import 'package:mochi_player/core/infrastructure/tmdb/tmdb_image_cache_manager.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/library/presentation/view_models/media_detail_view_model.dart';
import 'package:mochi_player/features/library/presentation/widgets/media_detail/favorite_button.dart';
import 'package:mochi_player/features/library/presentation/widgets/media_rating_tag.dart';
import 'package:mochi_player/features/playback/presentation/playback_launcher.dart';

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
            viewModel.overview,
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
      queryKey: viewModel.tmdbId,
      query: (r) => r.watchVersions(viewModel.tmdbId),
      initialData: const [],
      builder: (context, files) => _ActionRow(viewModel: viewModel, action: _resolvePrimaryAction(context, files)),
    );
  }

  _PrimaryPlayAction _resolvePrimaryAction(BuildContext context, List<MediaFile> files) {
    if (viewModel.isTVShow) {
      final target = EpisodePlaybackTargetResolver.resolveForShowPlayback(files);
      if (target == null) {
        return const _PrimaryPlayAction(label: '不可播放', detail: '未找到可播放剧集', enabled: false);
      }
      final verb = target.resumesCurrentEpisode ? '继续' : '播放';
      return _PrimaryPlayAction(
        label: _episodeActionLabel(target.file, verb),
        detail: target.resumesCurrentEpisode ? _resumeDetail(target.file) : _episodeCountDetail(files),
        onPressed: () => PlaybackLauncher.playFile(context, target.file, contextTitle: viewModel.title),
      );
    }

    final resumeFile = _latestResumeFile(files);

    if (resumeFile != null) {
      return _PrimaryPlayAction(
        label: '继续播放',
        detail: _resumeDetail(resumeFile),
        onPressed: () => PlaybackLauncher.playFile(context, resumeFile),
      );
    }

    final movie = viewModel.movie;
    if (movie != null) {
      return _PrimaryPlayAction(
        label: '播放',
        enabled: files.isNotEmpty,
        onPressed: files.isEmpty ? null : () => PlaybackLauncher.playMovie(context, movie),
      );
    }

    return const _PrimaryPlayAction(label: '不可播放', enabled: false);
  }

  MediaFile? _latestResumeFile(List<MediaFile> files) {
    final candidates = files.where((file) => file.position > 0 && file.progress > 0 && file.progress < 0.95).toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => (b.lastWatchedAt ?? DateTime(0)).compareTo(a.lastWatchedAt ?? DateTime(0)));
    return candidates.first;
  }

  String _episodeActionLabel(MediaFile file, String verb) {
    final episode = file.parsedEpisode;
    if (episode != null) return '$verb第 $episode 集';

    return '$verb第 ?? 集';
  }

  String _resumeDetail(MediaFile file) {
    if (file.duration <= 0) return '从上次进度继续';
    return '从 ${MediaFormat.clockDuration(Duration(milliseconds: file.position))} 继续';
  }

  String _episodeCountDetail(List<MediaFile> files) {
    final count = files.where((file) => file.mediaType == MediaType.episode).length;
    return count == 1 ? '1 集可播放' : '$count 集可播放';
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
        items.add(AppTag(text: '共 $totalSeasonCount 季', appearance: AppAppearance.overlay));
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
        FavoriteButton(tmdbId: viewModel.tmdbId, overrideColor: Colors.white, showLabel: true),
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
