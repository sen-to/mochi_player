import 'dart:io';

import 'package:mochi_player/core/domain/media/library_search_text.dart';
import 'package:sqlite3/sqlite3.dart';

/// Applied to every SQLite connection, including isolated player engines.
void configureSqlite(Database db) {
  db.execute('PRAGMA busy_timeout = 5000');
  // Changing journal mode can return SQLITE_BUSY immediately, even with a busy
  // timeout, when another engine opens the new file at the same time.
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
