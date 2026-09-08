import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:mochi_player/app/routing/app_route_paths.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/library/application/media_library_provider.dart';
import 'package:mochi_player/features/library/presentation/view_models/media_detail_view_model.dart';
import 'package:mochi_player/features/library/presentation/widgets/media_detail/cast_list.dart';
import 'package:mochi_player/features/library/presentation/widgets/media_detail/episode_list.dart';
import 'package:mochi_player/features/library/presentation/widgets/media_detail/media_detail_header.dart';
import 'package:mochi_player/features/playback/presentation/playback_launcher.dart';
import 'package:provider/provider.dart';

void openMediaDetailPage(BuildContext context, LibraryItem item) {
  context.push(AppRoutePaths.mediaDetail(context), extra: item);
}

class MediaDetailPage extends StatelessWidget {
  final LibraryItem item;

  const MediaDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final viewModel = MediaDetailViewModel(item);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(child: _MediaDetailContent(viewModel: viewModel)),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: AppHeader.height,
            child: AppHeader.back(title: viewModel.title),
          ),
        ],
      ),
    );
  }
}

class _MediaDetailContent extends StatelessWidget {
  final MediaDetailViewModel viewModel;

  const _MediaDetailContent({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final tvShow = viewModel.tvShow;
    return CustomScrollView(
      scrollCacheExtent: const ScrollCacheExtent.pixels(320),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: AppHeader.height)),
        SliverToBoxAdapter(child: MediaDetailHeader(viewModel: viewModel)),

        if (tvShow != null) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, AppSpacing.xxl),
            sliver: EpisodeList(tvShow: tvShow),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, 44),
            sliver: SliverToBoxAdapter(child: CastList(viewModel: viewModel, topPadding: 0)),
          ),
        ] else ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, 28, AppSpacing.page, 0),
            sliver: SliverToBoxAdapter(child: _MovieMediaInfoSection(viewModel: viewModel)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, 28, AppSpacing.page, 0),
            sliver: SliverToBoxAdapter(child: _OverviewSection(viewModel: viewModel)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, 44),
            sliver: SliverToBoxAdapter(child: CastList(viewModel: viewModel, topPadding: 20)),
          ),
        ],
      ],
    );
  }
}

class _MovieMediaInfoSection extends StatelessWidget {
  final MediaDetailViewModel viewModel;

  const _MovieMediaInfoSection({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    context.select<MediaLibraryProvider, (int, int)>(
      (provider) => (provider.mediaCatalogRevision, provider.watchProgressRevision),
    );
    final files = context.read<MediaLibraryProvider>().getVersions(viewModel.tmdbId)..sort(_compareVersions);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: '可播放版本',
          trailing: files.isEmpty
              ? null
              : files.length == 1
              ? '1 个文件'
              : '${files.length} 个文件',
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
            child: Text('未找到可播放的本地文件', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
          )
        else
          Column(
            children: [
              for (var index = 0; index < files.length; index++) ...[
                _VersionRow(
                  file: files[index],
                  theme: theme,
                  onTap: () => PlaybackLauncher.playFile(context, files[index]),
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
  final MediaDetailViewModel viewModel;

  const _OverviewSection({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: '简介'),
        const SizedBox(height: 10),
        Text(
          viewModel.overview,
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
                  MediaFileLabels.playableVersionTitle(file),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  MediaFileLabels.playableVersionDetails(file),
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
