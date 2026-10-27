// 【播放模型】保存播放 URL、请求头及可选的运行时资源。
// 目标资源要求幂等关闭，释放顺序由播放会话决定。

/// 媒体位置及打开它所需的请求头。
class PlaybackTarget {
  final String url;
  final Map<String, String> httpHeaders;
  final PlaybackTargetResource? resource;

  const PlaybackTarget({required this.url, this.httpHeaders = const {}, this.resource});

  /// 由播放会话持有；后端停止使用后再释放。
  Future<void> release() async => resource?.close();
}

/// 播放目标的可选运行时资源，实现必须支持幂等关闭。
abstract interface class PlaybackTargetResource {
  Future<void> close();
}
