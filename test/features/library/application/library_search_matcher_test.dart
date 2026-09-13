import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/features/library/application/library_search_matcher.dart';
import 'package:mochi_player/features/library/application/media_card_view_data.dart';

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

    expect(LibrarySearchMatcher.libraryItems(items, '电锯'), [saw]);
    expect(LibrarySearchMatcher.libraryItems(items, 'attack on titan'), [titan]);
    expect(LibrarySearchMatcher.libraryItems(items, '2006'), isEmpty);
    expect(LibrarySearchMatcher.libraryItems(items, '恐怖'), isEmpty);
    expect(LibrarySearchMatcher.libraryItems(items, 'Tobin Bell'), isEmpty);
  });

  test('ranks exact title before a contained title', () {
    const exact = Movie(tmdbId: '3', title: 'Saw');
    final results = LibrarySearchMatcher.libraryItems<LibraryItem>([saw, exact], 'Saw');

    expect(results, [exact, saw]);
  });

  test('matches favorite titles but ignores file metadata', () {
    final file = MediaFile(
      id: 1,
      path: '/movies/saw.mkv',
      fileName: 'Saw.III.2006.Remux.mkv',
      parsedTitle: '电锯惊魂3',
      size: 1,
      addedAt: DateTime(2026),
    );
    final card = MediaCardViewData(file: file, libraryItem: saw, title: saw.title);

    expect(LibrarySearchMatcher.mediaCards([card], '电锯惊魂3'), [card]);
    expect(LibrarySearchMatcher.mediaCards([card], 'Remux'), isEmpty);
  });

  test('returns the original order for an empty query', () {
    final items = <LibraryItem>[titan, saw];
    expect(LibrarySearchMatcher.libraryItems(items, '  '), items);
  });
}
