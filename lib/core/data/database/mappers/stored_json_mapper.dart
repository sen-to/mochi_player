// 【持久化映射】转换数据库中的字符串列表和演员 JSON 字段。
// 只处理存储格式，不发起查询；业务模型不实现 JSON 序列化。

import 'dart:convert';

import 'package:mochi_player/core/domain/media/artist.dart';

abstract final class StoredJsonMapper {
  static List<String> decodeStrings(String value) => (jsonDecode(value) as List).cast<String>();
  static String encodeStrings(List<String> value) => jsonEncode(value);

  static List<Artist> decodeArtists(String value) => (jsonDecode(value) as List)
      .map((entry) {
        final row = entry as Map<String, dynamic>;
        return Artist(
          tmdbId: row['tmdbId'] as String?,
          name: row['name'] as String,
          character: row['character'] as String?,
          profileUrl: row['profileUrl'] as String?,
        );
      })
      .toList(growable: false);

  static String encodeArtists(List<Artist> value) => jsonEncode([
    for (final artist in value)
      {'tmdbId': artist.tmdbId, 'name': artist.name, 'character': artist.character, 'profileUrl': artist.profileUrl},
  ]);
}
