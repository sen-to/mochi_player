// 【匹配结果模型】表达确认、未匹配及匹配依据。
// 请求失败单独报告，不在结果模型内执行搜索或持久化。

import 'package:mochi_player/core/domain/media/models.dart';

class MetadataMatch<T> {
  const MetadataMatch._({required this.status, this.metadata, this.source, this.query});

  const MetadataMatch.unmatched() : this._(status: MetadataMatchStatus.unmatched);

  factory MetadataMatch.confirmed(T metadata, {required MetadataMatchSource source, String? query}) =>
      MetadataMatch._(status: MetadataMatchStatus.confirmed, metadata: metadata, source: source, query: query);

  final MetadataMatchStatus status;
  final T? metadata;
  final MetadataMatchSource? source;
  final String? query;

  bool get isConfirmed => status == MetadataMatchStatus.confirmed;
}

enum MetadataMatchSource { localId, explicitId, titleSearch }
