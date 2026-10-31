// 【详情界面】组合媒体头部、版本、简介、季集与演员。
// 订阅媒体库入口，独立展示模型只负责字段适配。

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mochi_player/app/routing/app_route_paths.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/library/detail/ui/cast_list.dart';
import 'package:mochi_player/features/library/detail/ui/episode_list.dart';
import 'package:mochi_player/features/library/detail/ui/media_detail_header.dart';
import 'package:mochi_player/features/library/detail/ui/media_detail_mapper.dart';
import 'package:mochi_player/features/library/detail/ui/media_detail_vo.dart';
import 'package:mochi_player/features/library/ui/library_playback_launcher.dart';
import 'package:mochi_player/features/library/ui/widgets/library_query_view.dart';
import 'package:mochi_player/l10n/l10n.dart';

void openMediaDetailPage(BuildContext context, LibraryItem item) {
  context.push(AppRoutePaths.mediaDetail(context), extra: item);
}

class MediaDetailPage extends StatelessWidget {
  final LibraryItem item;

  const MediaDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return LibraryQueryView<LibraryItem?>(
      queryKey: (item.runtimeType, item.tmdbId),
      query: (r) => r.watchDetail(item),
      initialData: item,
      builder: (context, current) => _buildDetail(context, current ?? item),
    );
  }

  Widget _buildDetail(BuildContext context, LibraryItem current) {
    final details = MediaDetailMapper.toVO(current);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(child: _MediaDetailContent(details: details)),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: AppHeader.height,
            child: AppHeader.back(title: details.title),
          ),
        ],
      ),
    );
  }
}

class _MediaDetailContent extends StatelessWidget {
  final MediaDetailVO details;

  const _MediaDetailContent({required this.details});

  @override
  Widget build(BuildContext context) {
    final tvShow = details.tvShow;
    return CustomScrollView(
      scrollCacheExtent: const ScrollCacheExtent.pixels(320),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: AppHeader.height)),
        SliverToBoxAdapter(child: MediaDetailHeader(details: details)),

        if (tvShow != null) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, AppSpacing.xxl),
            sliver: EpisodeList(tvShow: tvShow),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, 44),
            sliver: SliverToBoxAdapter(child: CastList(details: details, topPadding: 0)),
          ),
        ] else ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, 28, AppSpacing.page, 0),
            sliver: SliverToBoxAdapter(child: _MovieMediaInfoSection(details: details)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, 28, AppSpacing.page, 0),
            sliver: SliverToBoxAdapter(child: _OverviewSection(details: details)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, 44),
            sliver: SliverToBoxAdapter(child: CastList(details: details, topPadding: 20)),
          ),
        ],
      ],
    );
  }
}

class _MovieMediaInfoSection extends StatelessWidget {
  final MediaDetailVO details;

  const _MovieMediaInfoSection({required this.details});

  @override
  Widget build(BuildContext context) {
    return LibraryQueryView<List<MediaFile>>(
      queryKey: (details.item.runtimeType, details.tmdbId),
      query: (r) => r.watchVersions(details.item),
      initialData: const [],
      builder: (context, versions) => _buildVersions(context, List.of(versions)..sort(_compareVersions)),
    );
  }

  Widget _buildVersions(BuildContext context, List<MediaFile> files) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: context.l10n.playableVersions,
          trailing: files.isEmpty ? null : context.l10n.fileCount(files.length),
        ),
        const SizedBox(height: 8),
        if (files.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.subtleSurface(context),
              borderRadius: BorderRadius.circular(AppRadii.control),
            ),
            child: Text(context.l10n.noPlayableLocalFiles, style: TextStyle(color: theme.textTheme.bodySmall?.color)),
          )
        else
          Column(
            children: [
              for (var index = 0; index < files.length; index++) ...[
                _VersionRow(
                  file: files[index],
                  theme: theme,
                  onTap: () => LibraryPlaybackLauncher.playFile(context, files[index]),
                ),
                if (index != files.length - 1) const SizedBox(height: 10),
              ],
            ],
          ),
      ],
    );
  }

  int _compareVersions(MediaFile a, MediaFile b) {
    final heightCompare = (b.height ?? 0).compareTo(a.height ?? 0);
    if (heightCompare != 0) return heightCompare;
    return b.size.compareTo(a.size);
  }
}

class _OverviewSection extends StatelessWidget {
  final MediaDetailVO details;

  const _OverviewSection({required this.details});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: context.l10n.overview),
        const SizedBox(height: 10),
        Text(
          details.overview ?? context.l10n.noOverview,
          style: TextStyle(fontSize: 14, height: 1.55, color: theme.textTheme.bodyMedium?.color?.withAlpha(220)),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? trailing;

  const _SectionTitle({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 10),
          Text(
            trailing!,
            style: TextStyle(fontSize: 13, color: theme.textTheme.bodySmall?.color, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }
}

class _VersionRow extends StatelessWidget {
  final MediaFile file;
  final ThemeData theme;
  final VoidCallback onTap;

  const _VersionRow({required this.file, required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(10);
    return AppClickableArea(
      onTap: onTap,
      borderRadius: borderRadius,
      backgroundColor: Colors.transparent,
      hoverColor: AppColors.hoverSurface(context),
      borderColor: AppColors.separator(context),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.primary.withAlpha(46)),
            ),
            alignment: Alignment.center,
            child: Icon(AppIcons.video, color: theme.colorScheme.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  MediaFileLabels.detailVersionTitle(file),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  MediaFileLabels.detailVersionSubtitle(file, l10n: context.l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color),
                ),
                const SizedBox(height: 2),
                Text(
                  file.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: theme.textTheme.bodySmall?.color?.withAlpha(180)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
