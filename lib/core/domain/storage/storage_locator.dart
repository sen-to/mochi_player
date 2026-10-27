// 【共享模型】用来源身份与相对路径定位一个存储条目。
// 不读取凭据或实际文件内容。

/// 定位某个配置来源内的存储条目。
class StorageLocator {
  final String sourceId;
  final String path;

  const StorageLocator({required this.sourceId, required this.path});

  String get storageKey => keyFor(sourceId, path);

  static String keyFor(String sourceId, String path) => '$sourceId:$path';
}
