// 【持久化契约】定义播放会话需要的文件读取和进度更新。
// 会话只依赖此能力，数据库实现位于 data。

import 'package:mochi_player/core/domain/media/media_file.dart';

/// 播放会话需要的最小持久化能力；独立视图只加载自己的队列，不必加载完整媒体目录及元数据。
abstract interface class PlaybackMediaRepository {
  /// sourceId 和来源相对 path 共同定位物理文件；记录不存在返回 null，读取失败抛出异常。
  Future<MediaFile?> readMediaFile({required String sourceId, required String path});

  /// position / duration 单位为毫秒；仅更新时长、位置、观看状态和最近观看时间。
  /// 记录已删除时直接结束，数据库失败抛出异常；不覆盖收藏或元数据关联。
  Future<void> updateProgress(MediaFile file, int position, {int? duration});
}
