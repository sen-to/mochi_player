import 'dart:async';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/infrastructure/storage/storage_adapter_registry.dart';
import 'package:mochi_player/core/infrastructure/storage/storage_source_repository.dart';

/// Application entry for source configuration and temporary connection tests.
class StorageSourcesService {
  StorageSourcesService({
    required StorageSourceRepository repository,
    required StorageAdapterRegistry registry,
    required void Function(String) onSourceRemoved,
  }) : _repository = repository,
       _registry = registry,
       _onSourceRemoved = onSourceRemoved;

  final StorageSourceRepository _repository;
  final StorageAdapterRegistry _registry;
  final void Function(String) _onSourceRemoved;

  bool _shuttingDown = false;
  final Set<Future<Object?>> _pending = {};

  void beginShutdown() => _shuttingDown = true;

  Future<void> drain() async {
    await Future.wait(_pending.map((operation) => operation.then<void>((_) {}, onError: (Object _, StackTrace __) {})));
  }

  Future<T> _run<T>(Future<T> Function() action) {
    if (_shuttingDown) return Future.error(StateError('Storage source operations are shutting down'));
    final operation = Future<T>.sync(action);
    _pending.add(operation);
    unawaited(
      operation.then<void>(
        (_) => _pending.remove(operation),
        onError: (Object _, StackTrace __) {
          _pending.remove(operation);
        },
      ),
    );
    return operation;
  }

  Future<List<StorageSource>> getAll() => _run(_repository.getAll);
  Future<void> save(StorageSource source, {StorageCredentials? credentials}) =>
      _run(() => _repository.save(source, credentials: credentials));
  Future<StorageCredentials?> readCredentials(String id) => _run(() => _repository.readCredentials(id));

  Future<int?> deleteWithMedia(String id) => _run(() async {
    final count = await _repository.deleteWithMedia(id);
    if (count != null) _onSourceRemoved(id);
    return count;
  });

  Future<int> testConnection(StorageSource source, StorageCredentials? credentials) => _run(() async {
    final connection = await _registry.connect(source, credentials);
    try {
      return (await connection.readDirectory('/')).length;
    } finally {
      await connection.close();
    }
  });
}
