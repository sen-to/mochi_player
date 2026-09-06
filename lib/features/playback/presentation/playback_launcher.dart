import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/library/application/media_library_provider.dart';
import 'package:mochi_player/features/playback/domain/player_window_request.dart';
import 'package:mochi_player/features/playback/presentation/player_window_app.dart';
import 'package:provider/provider.dart';

class PlaybackLauncher {
  static void playFile(
    BuildContext context,
    MediaFile file, {
    String? contextTitle,
    String? loadingMessage,
    String? failureMessage,
    List<MediaFile> playlist = const [],
  }) {
    _openPlayer(
      context,
      file,
      contextTitle: contextTitle,
      loadingMessage: loadingMessage,
      failureMessage: failureMessage,
      playlist: playlist,
    );
  }

  static void playLibraryItem(BuildContext context, LibraryItem item) {
    if (item is Movie) {
      playMovie(context, item);
      return;
    }

    if (item is TVShow) {
      playTVShow(context, item);
      return;
    }

    _showError(context, "不支持播放此资源");
  }

  /// 播放电影：查找文件并播放（支持多版本选择）
  static void playMovie(BuildContext context, Movie movie) {
    final provider = Provider.of<MediaLibraryProvider>(context, listen: false);
    final versions = provider.getVersions(movie.tmdbId);

    if (versions.isEmpty) {
      _showError(context, "未找到这部电影的本地文件");
      return;
    }

    if (versions.length > 1) {
      _showVersionPicker(context, versions);
    } else {
      _openPlayer(context, versions.first);
    }
  }

  /// 播放剧集：续播未看完的一集，或在看完后进入下一集。
  static void playTVShow(BuildContext context, TVShow show) {
    final provider = Provider.of<MediaLibraryProvider>(context, listen: false);
    final versions = provider.getVersions(show.tmdbId);
    final target = EpisodePlaybackTargetResolver.resolveForShowPlayback(versions);

    if (target == null) {
      _showError(context, "未找到可播放剧集");
      return;
    }

    _openPlayer(context, target.file, contextTitle: show.title);
  }

  /// 播放剧集：查找对应 Episode 的文件并播放
  static void playEpisode(BuildContext context, Episode episode, {required String showTitle}) {
    final provider = Provider.of<MediaLibraryProvider>(context, listen: false);

    MediaFile? targetFile;
    try {
      targetFile = provider.mediaFiles.firstWhere((f) => f.episodeTmdbId == episode.tmdbId);
    } catch (_) {}

    if (targetFile == null) {
      _showError(context, "未找到这一集的本地文件");
      return;
    }

    _openPlayer(context, targetFile, contextTitle: showTitle);
  }

  /// 核心播放逻辑：构造可持久化请求 -> 打开或复用独立播放器窗口。
  static void _openPlayer(
    BuildContext context,
    MediaFile file, {
    String? contextTitle,
    String? loadingMessage,
    String? failureMessage,
    List<MediaFile> playlist = const [],
  }) async {
    AppMessageHandle? loadingBanner;
    final loadingDelay = Timer(const Duration(milliseconds: 180), () {
      if (!context.mounted) return;
      loadingBanner = AppMessage.loading(loadingMessage ?? '正在打开播放器…');
    });

    try {
      final libraryProvider = context.read<MediaLibraryProvider>();
      final queue = playlist.isNotEmpty ? playlist : libraryProvider.getPlaybackQueue(file);
      final request = PlayerWindowRequest.fromPlayback(initialMedia: file, queue: queue, contextTitle: contextTitle);
      await PlayerWindow.openOrReplace(request);
    } on PlayerWindowLaunchFailed catch (error) {
      debugPrint('播放器子窗口启动失败: $error');
    } catch (error, stackTrace) {
      debugPrint('打开播放器窗口失败: $error\n$stackTrace');
      if (context.mounted) {
        _showError(context, failureMessage ?? '无法打开播放器，请检查媒体源和网络');
      }
    } finally {
      loadingDelay.cancel();
      loadingBanner?.dismiss();
    }
  }

  static void _showError(BuildContext context, String message) {
    if (context.mounted) AppMessage.error(message);
  }

  /// 版本选择弹窗
  static void _showVersionPicker(BuildContext context, List<MediaFile> versions) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);

        return Container(
          decoration: BoxDecoration(
            color: AppColors.modalSurface(sheetContext),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "选择版本",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
                ),
              ),
              const Divider(height: 1),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: versions.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (ctx, index) {
                  final file = versions[index];
                  final label = MediaFileLabels.versionTitle(file);
                  return ListTile(
                    leading: Icon(Icons.movie_outlined, color: theme.colorScheme.primary),
                    title: Text(
                      label.isNotEmpty ? label : file.fileName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      MediaFileLabels.versionSubtitle(file, includeContainer: false),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext); // 关闭 Sheet
                      _openPlayer(context, file); // 使用外部 context
                    },
                  );
                },
              ),
              SizedBox(height: MediaQuery.of(sheetContext).padding.bottom + 16),
            ],
          ),
        );
      },
    );
  }
}
