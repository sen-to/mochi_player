// 【元数据模型】封装服务商返回的一季信息与可导入单集。
// 作为原子导入输入，不自行写入数据库。

import 'package:mochi_player/core/domain/media/episode.dart';
import 'package:mochi_player/core/domain/media/season.dart';

/// 可供原子导入的一季服务商元数据及可用单集。
class SeasonMetadata {
  const SeasonMetadata({required this.season, required this.episodes});

  final Season season;
  final List<Episode> episodes;
}
