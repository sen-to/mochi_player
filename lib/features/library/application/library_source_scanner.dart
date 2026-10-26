import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/storage/storage_source.dart';

/// Discovers enabled, supported sources and opens source-relative scan sessions.
abstract interface class LibrarySourceScanner {
  Future<List<StorageSource>> enabledSources();

  /// The caller owns the returned session and must close it even if scanning fails.
  Future<LibrarySourceScan> open(StorageSource source);
}

abstract interface class LibrarySourceScan {
  Stream<MediaFile> scan();

  /// A completed stream can still be incomplete due to unreadable directories.
  bool get hadReadError;

  Future<void> close();
}
