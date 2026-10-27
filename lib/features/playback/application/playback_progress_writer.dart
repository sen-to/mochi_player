// 【业务写入顺序】按请求顺序串行保存播放进度。
// 避免周期保存、跳转和关闭快照互相覆盖。

import 'package:mochi_player/core/domain/media/media_file.dart';

typedef PersistPlaybackProgress = Future<void> Function(MediaFile file, int position, {int? duration});

/// 按请求顺序串行保存进度；周期保存可能与跳转、换片或销毁保存重叠，串行执行可防止迟到的旧快照覆盖新位置。
class PlaybackProgressWriter {
  PlaybackProgressWriter(this._persist);

  final PersistPlaybackProgress _persist;
  Future<void> _tail = Future.value();

  Future<void> drain() => _tail;

  Future<void> save(MediaFile file, int position, {int? duration}) {
    final operation = _tail.then((_) => _persist(file, position, duration: duration));

    // 数据库写入失败后队列仍可继续使用，返回给调用方的 Future 保留失败供其报告。
    _tail = operation.catchError((Object _) {});
    return operation;
  }
}
