import 'package:dart_smb2/dart_smb2.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/domain/storage/smb_source_location.dart';

/// A protocol-neutral SMB directory entry, kept small so callers do not
/// depend on the third-party SMB client package.
class SmbDirectoryEntry {
  const SmbDirectoryEntry({
    required this.name,
    required this.isDirectory,
    required this.isFile,
    required this.size,
    required this.modifiedAt,
  });

  final String name;
  final bool isDirectory;
  final bool isFile;
  final int size;
  final DateTime modifiedAt;
}

abstract interface class SmbDirectoryClient {
  Future<List<SmbDirectoryEntry>> readDirectory(String path);

  Future<void> close();
}

/// Connects to an SMB2/3 share.
class SmbStorageProvider implements StorageProvider {
  SmbStorageProvider({Future<SmbDirectoryClient> Function(SmbSourceLocation, StorageCredentials?)? connect})
    : _connect = connect ?? _connectWithSmb2;

  final Future<SmbDirectoryClient> Function(SmbSourceLocation, StorageCredentials?) _connect;

  @override
  StorageSourceType get type => StorageSourceType.smb;

  @override
  Future<SmbStorageConnection> connect(StorageSource source, StorageCredentials? credentials) async {
    if (source.type != type) {
      throw ArgumentError.value(source.type, 'source.type', 'must be SMB');
    }
    final location = SmbSourceLocation.fromSource(source);
    final client = await _connect(location, credentials);
    return SmbStorageConnection(source: source, location: location, client: client);
  }

  static Future<SmbDirectoryClient> _connectWithSmb2(
    SmbSourceLocation location,
    StorageCredentials? credentials,
  ) async {
    final username = credentials?.username.trim() ?? '';
    final password = credentials?.password ?? '';
    final pool = await Smb2Pool.connect(
      host: location.host,
      share: location.share,
      user: username.isEmpty ? null : username,
      password: password.isEmpty ? null : password,
      workers: 1,
    );
    return _Smb2DirectoryClient(pool);
  }
}

/// Source-relative SMB connection used by file browsing and library scanning.
class SmbStorageConnection implements StorageConnection {
  SmbStorageConnection({required this.source, required SmbSourceLocation location, required SmbDirectoryClient client})
    : _location = location,
      _client = client {
    if (source.type != StorageSourceType.smb) {
      throw ArgumentError.value(source.type, 'source.type', 'must be SMB');
    }
  }

  @override
  final StorageSource source;
  final SmbSourceLocation _location;
  final SmbDirectoryClient _client;

  @override
  Future<List<StorageEntry>> readDirectory(String path) async {
    final entries = await _client.readDirectory(_location.resolve(path));
    return entries
        .where((entry) => entry.name.isNotEmpty && (entry.isDirectory || entry.isFile))
        .map(
          (entry) => StorageEntry(
            name: entry.name,
            isDirectory: entry.isDirectory,
            size: entry.size,
            modifiedAt: entry.modifiedAt,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<bool> testConnection() async {
    try {
      await readDirectory('/');
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> close() => _client.close();
}

class _Smb2DirectoryClient implements SmbDirectoryClient {
  const _Smb2DirectoryClient(this._pool);

  final Smb2Pool _pool;

  @override
  Future<List<SmbDirectoryEntry>> readDirectory(String path) async {
    final entries = await _pool.listDirectory(path);
    return entries
        .map(
          (entry) => SmbDirectoryEntry(
            name: entry.name,
            isDirectory: entry.isDirectory,
            isFile: entry.isFile,
            size: entry.size,
            modifiedAt: entry.stat.modified,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> close() => _pool.disconnect();
}
