/// Shared normalization for database search and title ranking.
String normalizeLibrarySearchText(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[\s\u3000._\-:：，。/\\\(\)\[\]【】]+'), '').trim();
