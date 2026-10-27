// 【持久化契约】定义播放会话需要的文件读取和进度更新。
// 会话只依赖此能力，数据库实现位于 infrastructure。

import 'package:mochi_player/core/domain/media/media_file.dart';

/// 播放会话需要的最小持久化能力；独立视图只加载自己的队列，不必加载完整媒体目录及元数据。
abstract interface class PlaybackMediaRepository {
  Future<MediaFile?> readMediaFile({required String sourceId, required String path});

  Future<void> updateProgress(MediaFile file, int position, {int? duration});
}
