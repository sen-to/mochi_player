// 【数据库初始化】为 SQLite 连接注册搜索规范化等公共能力。
// 正式连接与独立测试连接使用相同初始化规则。

import 'dart:io';

import 'package:mochi_player/core/domain/media/library_search_text.dart';
import 'package:sqlite3/sqlite3.dart';

/// 正式连接及独立打开的测试连接使用相同初始化。
void configureSqlite(Database db) {
  db.execute('PRAGMA busy_timeout = 5000');
  // 多个连接同时打开新文件时，切换日志模式即使设置了忙碌等待，也可能立即返回 SQLITE_BUSY。
  final elapsed = Stopwatch()..start();
  while (true) {
    try {
      if (db.select('PRAGMA journal_mode').single.values.first != 'wal') {
        db.execute('PRAGMA journal_mode = WAL');
      }
      break;
    } on SqliteException catch (error) {
      if (error.resultCode != 5 || elapsed.elapsedMilliseconds >= 5000) rethrow;
      sleep(const Duration(milliseconds: 25));
    }
  }
  db.createFunction(
    functionName: 'library_normalize',
    argumentCount: const AllowedArgumentCount(1),
    deterministic: true,
    function: (args) => normalizeLibrarySearchText(args[0] as String? ?? ''),
  );
}
