// 【展示映射】将媒体文件及已批量读取的标题元数据组合为卡片 VO。
// 不查询数据库，类型分组、标题回退和续播副标题只在此处转换。

import 'package:mochi_player/core/application/media_format.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/features/library/catalog/application/media_card_vo.dart';

abstract final class MediaCardMapper {
  static MediaCardVO toVO(MediaFile file, LibraryItem? item, {bool useBackdrop = false}) => MediaCardVO(
    file: file,
    libraryItem: item,
    title: item?.title ?? file.parsedTitle,
    subtitle: file.mediaType == MediaType.episode && useBackdrop
        ? MediaFormat.episodeCode(file)
        : item?.releaseYear?.toString(),
    imageUrl: useBackdrop ? item?.backdropUrl : item?.posterUrl,
    rating: item?.rating ?? 0,
    playbackContextTitle: file.mediaType == MediaType.episode ? item?.title : null,
  );
}
