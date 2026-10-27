// 【播放契约】根据媒体文件准备可播放的地址和认证信息。
// 返回目标的资源由播放会话接管。

import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/playback/playback_target.dart';

abstract interface class PlaybackTargetResolver {
  Future<PlaybackTarget?> resolve(MediaFile file);
}
