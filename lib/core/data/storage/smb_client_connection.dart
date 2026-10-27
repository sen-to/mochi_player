// 【协议连接】集中建立 SMB 客户端连接及认证参数。
// 供浏览与播放适配复用，不保存界面状态。

import 'package:dart_smb2/dart_smb2.dart';
import 'package:mochi_player/core/domain/storage/smb_source_location.dart';
import 'package:mochi_player/core/domain/storage/storage_credentials.dart';

// libsmb2 会初始化全局原生状态，因此浏览和播放之间也必须串行创建连接池，不能只约束单个池内的工作线程。
Future<void> _connecting = Future<void>.value();

Future<Smb2Pool> connectSmbPool(
  SmbSourceLocation location,
  StorageCredentials? credentials, {
  int timeoutSeconds = 30,
}) {
  final operation = _connecting.then((_) {
    final username = credentials?.username.trim() ?? '';
    final password = credentials?.password ?? '';
    return Smb2Pool.connect(
      host: location.host,
      share: location.share,
      user: username.isEmpty ? null : username,
      password: password.isEmpty ? null : password,
      workers: 1,
      timeoutSeconds: timeoutSeconds,
    );
  });
  _connecting = operation.then<void>((_) {}, onError: (Object _, StackTrace _) {});
  return operation;
}
