// 【业务入口】统一来源保存、删除、凭据读取及临时连接测试。
// 成功持久化后通知浏览失效；退出等待已接受任务，测试连接必须关闭。

import 'dart:async';

import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/domain/storage/storage_adapter_registry.dart';
import 'package:mochi_player/core/domain/storage/storage_source_repository.dart';

/// 媒体源配置及临时连接测试的业务入口。
class StorageSourcesService {
  StorageSourcesService({
    required StorageSourceRepository repository,
    required StorageAdapterRegistry registry,
    required bool Function(String) onSourceChanged,
  }) : _repository = repository,
       _registry = registry,
       _onSourceChanged = onSourceChanged;

  final StorageSourceRepository _repository;
  final StorageAdapterRegistry _registry;
  final bool Function(String) _onSourceChanged;

  bool _shuttingDown = false;
  final Set<Future<Object?>> _pending = {};

  void beginShutdown() => _shuttingDown = true;

  Future<void> drain() async {
    await Future.wait(_pending.map((operation) => operation.then<void>((_) {}, onError: (Object _, StackTrace _) {})));
  }

  Future<T> _run<T>(Future<T> Function() action) {
    if (_shuttingDown) return Future.error(StateError('Storage source operations are shutting down'));
    final operation = Future<T>.sync(action);
    _pending.add(operation);
    unawaited(
      operation.then<void>(
        (_) => _pending.remove(operation),
        onError: (Object _, StackTrace _) {
          _pending.remove(operation);
        },
      ),
    );
    return operation;
  }

  /// 按名称读取全部来源，包含禁用来源；不返回密码，读取失败抛出异常。
  Future<List<StorageSource>> getAll() => _run(_repository.getAll);

  /// 先保存来源，再使使用该来源的浏览状态失效；返回是否需要用新配置重新打开。
  Future<bool> save(StorageSource source, {StorageCredentials? credentials}) => _run(() async {
    await _repository.save(source, credentials: credentials);
    return _onSourceChanged(source.id);
  });

  /// 按来源 ID 读取凭据；来源不存在返回 null，读取失败抛出异常。
  Future<StorageCredentials?> readCredentials(String id) => _run(() => _repository.readCredentials(id));

  /// 删除来源、凭据及关联文件索引，返回移除的索引数；来源不存在返回 null。
  /// 不删除磁盘文件或共享元数据；失败抛出异常，成功后通知浏览状态失效。
  Future<int?> deleteWithMedia(String id) => _run(() async {
    final count = await _repository.deleteWithMedia(id);
    if (count != null) _onSourceChanged(id);
    return count;
  });

  /// 建立临时连接并读取根目录；读取成功即完成，空目录也视为成功。
  /// 建连、读取或关闭失败均抛出异常；已创建的连接始终在 finally 中关闭。
  Future<void> testConnection(StorageSource source, StorageCredentials? credentials) => _run(() async {
    final connection = await _registry.connect(source, credentials);
    try {
      await connection.readDirectory('/');
    } finally {
      await connection.close();
    }
  });
}
