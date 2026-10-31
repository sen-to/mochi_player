// 【行为测试】验证提供独立的标题搜索评分参考实现。
// 测试对象的职责边界：只供测试比较 SQL 查询结果，不随应用发布。

import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/media/models.dart';

import '../../../support/library_search_reference.dart';

void main() {
  const saw = Movie(
    tmdbId: '1',
    title: '电锯惊魂3',
    originalTitle: 'Saw III',
    releaseYear: 2006,
    genres: ['恐怖'],
    cast: [Artist(name: 'Tobin Bell', character: 'Jigsaw')],
  );
  const titan = TVShow(tmdbId: '2', title: '进击的巨人', originalTitle: 'Attack on Titan', releaseYear: 2013);

  test('matches localized and original titles only', () {
    final items = <LibraryItem>[saw, titan];

    expect(LibrarySearchReference.libraryItems(items, '电锯'), [saw]);
    expect(LibrarySearchReference.libraryItems(items, 'attack on titan'), [titan]);
    expect(LibrarySearchReference.libraryItems(items, '2006'), isEmpty);
    expect(LibrarySearchReference.libraryItems(items, '恐怖'), isEmpty);
    expect(LibrarySearchReference.libraryItems(items, 'Tobin Bell'), isEmpty);
  });

  test('ranks exact title before a contained title', () {
    const exact = Movie(tmdbId: '3', title: 'Saw');
    final results = LibrarySearchReference.libraryItems<LibraryItem>([saw, exact], 'Saw');

    expect(results, [exact, saw]);
  });

  test('returns the original order for an empty query', () {
    final items = <LibraryItem>[titan, saw];
    expect(LibrarySearchReference.libraryItems(items, '  '), items);
  });
}
