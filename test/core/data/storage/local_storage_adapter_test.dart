// 【行为测试】验证读取用户配置的本地目录及文件条目。
// 测试对象的职责边界：路径相对来源根目录解析，连接由浏览或扫描流程管理。

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/data/storage/local_storage_adapter.dart';
import 'package:mochi_player/core/domain/storage/models.dart';

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

LocalStorageAdapter _provider() => LocalStorageAdapter();
