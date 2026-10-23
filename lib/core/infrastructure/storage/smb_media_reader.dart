import 'dart:async';
import 'dart:typed_data';

import 'package:dart_smb2/dart_smb2.dart';
import 'package:mochi_player/core/domain/storage/storage_credentials.dart';
import 'package:mochi_player/core/domain/storage/smb_source_location.dart';
import 'package:mochi_player/core/infrastructure/storage/smb_client_connection.dart';

/// One opened SMB file. Offsets are absolute; reads never change a shared cursor.
abstract interface class SmbMediaReader {
  int get length;
  Future<Uint8List> read(int offset, int length, {bool Function()? isCancelled});
  Future<void> close();
}

/// A superseded HTTP request must not start another native SMB read.
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
    // Serialize access to the one handle, including the package's reconnect /
    // reopen sequence when several HTTP range requests overlap.
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
      // Mark the handle closed even if a stalled read prevents its native
      // close from completing. Disconnect then terminates the worker.
      await _pool.closeHandle(_handle).timeout(const Duration(seconds: 1));
    } on TimeoutException {
      // The pool disconnect below has its own worker termination fallback.
    } finally {
      await _pool.disconnect();
    }
  }
}
