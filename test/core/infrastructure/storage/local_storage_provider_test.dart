import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/infrastructure/storage/local_storage_provider.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('mochi-local-source-');
    await Directory('${directory.path}/Movies').create();
    await File('${directory.path}/Movies/Example.mkv').writeAsBytes([1, 2]);
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test('lists source-relative local directories and files', () async {
    final connection = await _provider().connect(_source(directory), null);

    final rootEntries = await connection.readDirectory('/');
    final movieEntries = await connection.readDirectory('/Movies/');

    expect(rootEntries.single.name, 'Movies');
    expect(rootEntries.single.isDirectory, isTrue);
    expect(movieEntries.single.name, 'Example.mkv');
    expect(movieEntries.single.size, 2);
    expect(await connection.testConnection(), isTrue);
  });

  test('does not allow paths outside the selected directory', () async {
    final connection = await _provider().connect(_source(directory), null);

    expect(() => connection.readDirectory('/../'), throwsA(isA<ArgumentError>()));
  });
}

StorageSource _source(Directory directory) =>
    StorageSource(id: 'local-media', name: '本地媒体', type: StorageSourceType.local, endpoint: directory.path);

LocalStorageProvider _provider() => LocalStorageProvider();
