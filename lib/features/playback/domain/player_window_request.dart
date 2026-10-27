// 【播放请求模型】在同一引擎内传递初始文件、播放队列与上下文标题。
// 不包含原生播放器实例或数据库连接。

import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:uuid/uuid.dart';

class PlayerWindowRequest {
  PlayerWindowRequest.fromPlayback({
    required this.initialMedia,
    required List<MediaFile> queue,
    this.contextTitle,
    String? requestId,
  }) : requestId = requestId ?? const Uuid().v4(),
       queue = List.unmodifiable(queue);

  final String requestId;
  final MediaFile initialMedia;
  final List<MediaFile> queue;
  final String? contextTitle;
}
