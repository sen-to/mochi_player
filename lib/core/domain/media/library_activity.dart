// 【媒体活动模型】描述扫描与刮削的当前进度、成功及失败数量。
// 由媒体库任务更新，界面和本地化只读取快照，不负责推进任务。

enum LibraryActivityKind { scanning, scraping }

class LibraryActivity {
  const LibraryActivity({
    required this.kind,
    required this.completed,
    required this.total,
    this.success = 0,
    this.failed = 0,
    this.title = '',
  });

  final LibraryActivityKind kind;
  final int completed;
  final int total;
  final int success;
  final int failed;
  final String title;
}
