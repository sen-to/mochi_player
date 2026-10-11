import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:mochi_player/core/domain/media/artist.dart';

class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) => (jsonDecode(fromDb) as List).cast<String>();

  @override
  String toSql(List<String> value) => jsonEncode(value);
}

class ArtistListConverter extends TypeConverter<List<Artist>, String> {
  const ArtistListConverter();

  @override
  List<Artist> fromSql(String fromDb) => (jsonDecode(fromDb) as List).map((value) {
    final artist = value as Map<String, dynamic>;
    return Artist(
      tmdbId: artist['tmdbId'] as String?,
      name: artist['name'] as String,
      character: artist['character'] as String?,
      profileUrl: artist['profileUrl'] as String?,
    );
  }).toList();

  @override
  String toSql(List<Artist> value) => jsonEncode(
    value
        .map(
          (artist) => {
            'tmdbId': artist.tmdbId,
            'name': artist.name,
            'character': artist.character,
            'profileUrl': artist.profileUrl,
          },
        )
        .toList(),
  );
}
