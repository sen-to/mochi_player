import 'package:mochi_player/core/domain/media/library_item.dart';
import 'package:mochi_player/core/domain/media/library_search_text.dart';
import 'package:mochi_player/features/library/catalog/media_card_view_data.dart';

/// Independent reference scorer for verifying SQL search ranking.
///
/// Production searches execute in LibraryRepository; this implementation is test-only.
abstract final class LibrarySearchReference {
  static List<T> libraryItems<T extends LibraryItem>(Iterable<T> items, String query) {
    return _rank(items, query, _libraryItemScore);
  }

  static List<MediaCardViewData> mediaCards(Iterable<MediaCardViewData> items, String query) {
    return _rank(items, query, _mediaCardScore);
  }

  static List<T> _rank<T>(Iterable<T> items, String query, int Function(T item, String normalizedQuery) score) {
    final normalizedQuery = normalizeLibrarySearchText(query);
    final values = items.toList();
    if (normalizedQuery.isEmpty) return values;

    final matches = <_RankedValue<T>>[];
    for (var index = 0; index < values.length; index++) {
      final value = values[index];
      final valueScore = score(value, normalizedQuery);
      if (valueScore > 0) {
        matches.add(_RankedValue(value, valueScore, index));
      }
    }
    matches.sort((a, b) {
      final scoreOrder = b.score.compareTo(a.score);
      return scoreOrder != 0 ? scoreOrder : a.originalIndex.compareTo(b.originalIndex);
    });
    return matches.map((match) => match.value).toList();
  }

  static int _libraryItemScore(LibraryItem item, String normalizedQuery) {
    final score = _textScore(item.title, normalizedQuery, exact: 120);
    return _max(score, _textScore(item.originalTitle, normalizedQuery, exact: 110));
  }

  static int _mediaCardScore(MediaCardViewData item, String normalizedQuery) {
    final score = item.libraryItem == null ? 0 : _libraryItemScore(item.libraryItem!, normalizedQuery);
    return _max(score, _textScore(item.title, normalizedQuery, exact: 120));
  }

  static int _textScore(String? value, String query, {required int exact}) {
    final normalizedValue = normalizeLibrarySearchText(value ?? '');
    if (normalizedValue.isEmpty) return 0;
    if (normalizedValue == query) return exact;
    if (normalizedValue.startsWith(query)) return exact - 20;
    if (normalizedValue.contains(query)) return exact - 40;

    return 0;
  }

  static int _max(int a, int b) => a > b ? a : b;
}

class _RankedValue<T> {
  const _RankedValue(this.value, this.score, this.originalIndex);

  final T value;
  final int score;
  final int originalIndex;
}
