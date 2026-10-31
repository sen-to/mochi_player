// 【持久化契约】定义扫描流程需要的路径、批量写入、清理及待匹配读取。
// 事务与 SQL 留在 data 中的数据库实现。

import 'package:mochi_player/core/domain/media/media_file.dart';

/// 同步流程需要的持久化契约，事务细节留在具体适配器。
abstract interface class LibrarySyncRepository {
  /// 读取该来源已索引文件的相对路径，空集合表示无文件，读取失败抛出异常。
  Future<Set<String>> sourcePaths(String sourceId);

  /// 按来源和路径批量新增 / 更新文件，已存在来源是调用方前置条件。
  /// 不覆盖用户状态；媒体类型变化时清除不再适用的匹配关联，失败整批回滚。
  Future<void> saveScannedFiles(List<MediaFile> files);

  /// seen 是本轮完整扫描见到的相对路径；仅在扫描完整且未中断后调用。
  /// 删除来源下不在 seen 中的索引并返回删除数，不删除物理文件或共享元数据；失败回滚。
  Future<int> removeMissingFiles(String sourceId, Set<String> seen);

  /// 返回缺失元数据或需要按显式 TMDB ID 重新匹配的文件；没有候选时为空列表。
  /// 只读取本地索引，不发起请求，数据库失败抛出异常。
  Future<List<MediaFile>> scrapeCandidates();
}
