import 'dart:typed_data';

import 'package:mochi_player/core/infrastructure/storage/smb_media_reader.dart';

class MemorySmbReader implements SmbMediaReader {
  MemorySmbReader(this.bytes, {this.beforeRead, this.onClose, this.maxRead});

  final Uint8List bytes;
  final Future<void> Function()? beforeRead;
  final void Function()? onClose;
  final int? maxRead;
  final reads = <(int, int)>[];
  int closeCalls = 0;

  @override
  int get length => bytes.length;

  @override
  Future<Uint8List> read(int offset, int length, {bool Function()? isCancelled}) async {
    if (isCancelled?.call() ?? false) throw const SmbReadCancelled();
    reads.add((offset, length));
    await beforeRead?.call();
    if (isCancelled?.call() ?? false) throw const SmbReadCancelled();
    if (closeCalls != 0) throw StateError('closed');
    final count = maxRead != null && maxRead! < length ? maxRead! : length;
    return Uint8List.sublistView(bytes, offset, offset + count);
  }

  @override
  Future<void> close() async {
    closeCalls++;
    onClose?.call();
  }
}
