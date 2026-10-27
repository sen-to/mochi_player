// 【共享模型】描述存储来源内的文件或目录条目。
// 只保存协议无关信息，不包含播放器或元数据状态。

/// 媒体来源内的一个文件或目录。
class StorageEntry {
  final String name;
  final bool isDirectory;
  final int size;
  final DateTime? modifiedAt;

  const StorageEntry({required this.name, required this.isDirectory, required this.size, required this.modifiedAt});
}
