// 【扫描契约】定义可扫描来源及来源内的扫描会话。
// 编排方在结束或失败时关闭会话，不直接管理协议凭据。

import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/storage/storage_source.dart';

/// 列出启用且受支持的来源，并打开来源相对路径的扫描会话。
abstract interface class LibrarySourceScanner {
  Future<List<StorageSource>> enabledSources();

  /// 调用方持有返回会话，扫描失败也必须关闭。
  Future<LibrarySourceScanSession> open(StorageSource source);
}

abstract interface class LibrarySourceScanSession {
  Stream<MediaFile> scan();

  /// 数据流正常结束仍可能包含无法读取的目录，不能据此认定扫描完整。
  bool get hadReadError;

  Future<void> close();
}
