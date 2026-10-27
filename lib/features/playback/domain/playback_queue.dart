// 【播放业务数据】维护一个会话的文件顺序与当前项。
// 不解析播放地址，不发出播放器命令。

import 'package:mochi_player/core/domain/media/media_file.dart';

/// 持有一个播放会话的有序文件；地址解析与播放器命令留在类外，队列可以脱离 Flutter 或播放后端独立测试。
class PlaybackQueue {
  PlaybackQueue({required MediaFile initialItem, required List<MediaFile> items}) : _items = _deduplicate(items) {
    _currentIndex = _items.indexWhere(
      (item) => item.id == initialItem.id || (item.sourceId == initialItem.sourceId && item.path == initialItem.path),
    );
    if (_currentIndex < 0) {
      _items.insert(0, initialItem);
      _currentIndex = 0;
    }
  }

  final List<MediaFile> _items;
  late int _currentIndex;

  MediaFile get current => _items[_currentIndex];

  int get currentIndex => _currentIndex;

  bool get hasPrevious => _currentIndex > 0;

  bool get hasNext => _currentIndex < _items.length - 1;

  MediaFile? itemAtOffset(int offset) {
    final index = _currentIndex + offset;
    if (index < 0 || index >= _items.length) return null;
    return _items[index];
  }

  void selectOffset(int offset) {
    final index = _currentIndex + offset;
    if (index < 0 || index >= _items.length) {
      throw RangeError.index(index, _items, 'offset');
    }
    _currentIndex = index;
  }

  void replaceCurrent(MediaFile item) {
    _items[_currentIndex] = item;
  }

  static List<MediaFile> _deduplicate(List<MediaFile> items) {
    final seenPaths = <String>{};
    return [
      for (final item in items)
        if (seenPaths.add('${item.sourceId}:${item.path}')) item,
    ];
  }
}
