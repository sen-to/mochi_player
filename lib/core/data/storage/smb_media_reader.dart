// 【协议资源】提供一个已打开 SMB 文件的按偏移读取能力。
// 读取串行执行并检查取消，句柄由播放目标资源关闭。

import 'dart:async';
import 'dart:typed_data';

import 'package:dart_smb2/dart_smb2.dart';
import 'package:mochi_player/core/data/storage/smb_client_connection.dart';
import 'package:mochi_player/core/domain/storage/smb_source_location.dart';
import 'package:mochi_player/core/domain/storage/storage_credentials.dart';

/// 表示一个已打开的 SMB 文件；使用绝对偏移读取，不改变共享游标。
abstract interface class SmbMediaReader {
  int get length;
  Future<Uint8List> read(int offset, int length, {bool Function()? isCancelled});
  Future<void> close();
}

/// 被替换的 HTTP 请求不能再启动新的原生 SMB 读取。
class SmbReadCancelled implements Exception {
  const SmbReadCancelled();
}

class Smb2MediaReader implements SmbMediaReader {
  Smb2MediaReader._(this._pool, this._handle, this.length);

  final Smb2Pool _pool;
  final Smb2PoolHandle _handle;
  @override
  final int length;
  Future<void> _reads = Future<void>.value();
  Future<void>? _closing;

  static Future<SmbMediaReader> open(SmbSourceLocation location, StorageCredentials? credentials, String path) async {
    final pool = await connectSmbPool(location, credentials, timeoutSeconds: 8);
    try {
      final (handle, size) = await pool.openFileWithSize(location.resolve(path));
      return Smb2MediaReader._(pool, handle, size);
    } catch (_) {
      await pool.disconnect();
      rethrow;
    }
  }

  @override
  Future<Uint8List> read(int offset, int length, {bool Function()? isCancelled}) {
    // 串行访问同一个文件句柄，包括多个 HTTP 范围请求重叠时第三方库的重连和重开过程。
    final operation = _reads.then((_) {
      if (isCancelled?.call() ?? false) throw const SmbReadCancelled();
      if (_closing != null) throw StateError('SMB media reader is closed');
      return _pool.readFromHandle(_handle, offset: offset, length: length);
    });
    _reads = operation.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return operation;
  }

  @override
  Future<void> close() => _closing ??= _close();

  Future<void> _close() async {
    try {
      // 即使阻塞读取导致原生关闭无法完成，也先标记句柄已关闭；随后断开连接终止工作线程。
      await _pool.closeHandle(_handle).timeout(const Duration(seconds: 1));
    } on TimeoutException {
      // 下方的连接池断开操作自带工作线程终止兜底。
    } finally {
      await _pool.disconnect();
    }
  }
}
