// 【持久化契约】定义扫描流程需要的路径、批量写入、清理及待匹配读取。
// 事务与 SQL 留在 data 中的数据库实现。

import 'package:mochi_player/core/domain/media/media_file.dart';

/// 同步流程需要的持久化契约，事务细节留在具体适配器。
abstract interface class LibrarySyncRepository {
  Future<Set<String>> sourcePaths(String sourceId);

  /// 只更新扫描属性，不覆盖匹配关系或用户状态。
  Future<void> saveScannedFiles(List<MediaFile> files);

  /// 仅在来源扫描完整且未中断后调用。
  Future<int> removeMissingFiles(String sourceId, Set<String> seen);

  Future<List<MediaFile>> scrapeCandidates();
}
