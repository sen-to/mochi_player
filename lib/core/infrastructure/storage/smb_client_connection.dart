import 'package:dart_smb2/dart_smb2.dart';
import 'package:mochi_player/core/domain/storage/storage_credentials.dart';
import 'package:mochi_player/core/domain/storage/smb_source_location.dart';

// libsmb2 initializes global native state: serialize pool creation across
// browsing and playback, not just the workers within an individual pool.
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
