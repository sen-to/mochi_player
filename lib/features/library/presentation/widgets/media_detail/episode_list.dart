import 'package:mochi_player/core/domain/media/watch_progress_policy.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/infrastructure/tmdb/tmdb_image_cache_manager.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/library/presentation/widgets/library_query.dart';
import 'package:mochi_player/features/playback/presentation/playback_launcher.dart';
import 'package:mochi_player/l10n/l10n.dart';

class EpisodeList extends StatefulWidget {
  final TVShow tvShow;

  const EpisodeList({super.key, required this.tvShow});

  @override
  State<EpisodeList> createState() => _EpisodeListState();
}

class _EpisodeListState extends State<EpisodeList> {
  List<Season> _sortedSeasons = [];
  Season? _selectedSeason;
  List<Episode> _sortedEpisodes = [];

  @override
  void initState() {
    super.initState();
    _prepareSeasons();
  }

  @override
  void didUpdateWidget(covariant EpisodeList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tvShow != widget.tvShow) {
      _prepareSeasons();
    }
  }

  void _prepareSeasons() {
    final selectedNumber = _selectedSeason?.seasonNumber;
    _sortedSeasons = List.from(widget.tvShow.seasons)..sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));

    if (_sortedSeasons.isNotEmpty) {
      _selectedSeason = _sortedSeasons.firstWhere(
        (season) => season.seasonNumber == selectedNumber,
        orElse: () => _sortedSeasons.first,
      );
      _sortedEpisodes = _sortedEpisodesFor(_selectedSeason!);
    } else {
      _selectedSeason = null;
      _sortedEpisodes = [];
    }
  }

  Map<String, MediaFile> _buildMediaFileIndex(List<MediaFile> mediaFiles) {
    final result = <String, MediaFile>{};
    for (final file in mediaFiles) {
      final key = file.episodeKey;
      if (key != null) {
        result.putIfAbsent(key, () => file);
      }
    }
    return result;
  }

  List<Episode> _sortedEpisodesFor(Season season) {
    return List<Episode>.from(season.episodes)..sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));
  }

  void _selectSeason(Season season) {
    setState(() {
      _selectedSeason = season;
      _sortedEpisodes = _sortedEpisodesFor(season);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LibraryQuery<List<MediaFile>>(
      queryKey: widget.tvShow.tmdbId,
      query: (r) => r.watchVersions(widget.tvShow),
      initialData: const [],
      sliver: true,
      builder: (context, files) => _buildEpisodes(context, files),
    );
  }

  Widget _buildEpisodes(BuildContext context, List<MediaFile> files) {
    final mediaFileByEpisodeKey = _buildMediaFileIndex(files);

    if (_sortedSeasons.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 32),
          child: Text(context.l10n.noSeasonInfo, style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final theme = Theme.of(context);

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: _EpisodeHeader(
            theme: theme,
            sortedSeasons: _sortedSeasons,
            selectedSeason: _selectedSeason,
            onSeasonSelected: _selectSeason,
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index.isOdd) {
                return const SizedBox(height: 16);
              }

              final episode = _sortedEpisodes[index ~/ 2];
              return _buildEpisodeCard(context, episode, mediaFileByEpisodeKey[episode.episodeKey]);
            },
            childCount: _sortedEpisodes.isEmpty ? 0 : _sortedEpisodes.length * 2 - 1,
            addAutomaticKeepAlives: false,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  Widget _buildEpisodeCard(BuildContext context, Episode episode, MediaFile? episodeFile) {
    final theme = Theme.of(context);
    final available = episodeFile != null;
    final progress = episodeFile?.progress.clamp(0.0, 1.0) ?? 0.0;
    final completed =
        episodeFile?.watchStatus == WatchStatus.completed || progress >= WatchProgressPolicy.completionThreshold;
    final showStatus = !available || completed;

    return AppClickableArea(
      onTap: available ? () => PlaybackLauncher.playEpisode(context, episode, showTitle: widget.tvShow.title) : null,
      borderRadius: BorderRadius.circular(AppRadii.control),
      backgroundColor: AppColors.subtleSurface(context),
      hoverColor: AppColors.hoverSurface(context),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildStill(episode, episodeFile, theme),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${episode.episodeNumber}. ${episode.title}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: available ? theme.textTheme.bodyLarge?.color : theme.textTheme.bodySmall?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (showStatus) ...[
                      const SizedBox(width: 8),
                      _EpisodeStatusLabel(available: available, completed: completed),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  episode.overview ?? '',
                  style: TextStyle(fontSize: 13, height: 1.4, color: theme.textTheme.bodySmall?.color),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 9),
                _EpisodeMetaRow(episode: episode, file: episodeFile),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStill(Episode episode, MediaFile? file, ThemeData theme) {
    final progress = file?.progress.clamp(0.0, 1.0) ?? 0.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 132,
        height: 76,
        child: Stack(
          fit: StackFit.expand,
          children: [
            episode.stillUrl != null
                ? CachedNetworkImage(
                    cacheManager: TmdbImageCacheManager.instance,
                    imageUrl: episode.stillUrl!,
                    width: 132,
                    height: 76,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey[300]),
                    errorWidget: (context, url, error) => _stillPlaceholder(),
                  )
                : _stillPlaceholder(),
            if (file == null) Container(color: Colors.black.withAlpha(95)),
            if (progress > 0 && progress < WatchProgressPolicy.completionThreshold)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  backgroundColor: Colors.black.withAlpha(80),
                  valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _stillPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Icon(Icons.movie, color: Colors.grey),
    );
  }
}

class _EpisodeStatusLabel extends StatelessWidget {
  final bool available;
  final bool completed;

  const _EpisodeStatusLabel({required this.available, required this.completed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = !available
        ? context.l10n.missing
        : completed
        ? context.l10n.watched
        : '';
    if (label.isEmpty) return const SizedBox.shrink();

    final color = !available
        ? theme.textTheme.bodySmall?.color ?? Colors.grey
        : completed
        ? AppColors.success(context)
        : theme.colorScheme.primary;
    return SizedBox(
      height: 18,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

class _EpisodeMetaRow extends StatelessWidget {
  final Episode episode;
  final MediaFile? file;

  const _EpisodeMetaRow({required this.episode, required this.file});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parts = <String>[];
    if (episode.airDate != null) {
      parts.add(DateFormat.yMd(context.l10n.localeName).format(episode.airDate!));
    }
    final mediaFile = file;
    if (mediaFile != null && mediaFile.duration > 0) {
      parts.add(context.l10n.minutesDuration(mediaFile.duration ~/ 60000));
    }

    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join(' • '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color, fontWeight: FontWeight.w600),
    );
  }
}

class _EpisodeHeader extends StatelessWidget {
  final ThemeData theme;
  final List<Season> sortedSeasons;
  final Season? selectedSeason;
  final ValueChanged<Season> onSeasonSelected;

  const _EpisodeHeader({
    required this.theme,
    required this.sortedSeasons,
    required this.selectedSeason,
    required this.onSeasonSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.series,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
            ),
            SizedBox(
              width: 92,
              child: AppSelect<Season>(
                value: selectedSeason,
                placeholder: context.l10n.selectSeason,
                options: [
                  for (final season in sortedSeasons)
                    AppSelectOption(value: season, label: context.l10n.seasonLabel(season.seasonNumber)),
                ],
                onChanged: onSeasonSelected,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
