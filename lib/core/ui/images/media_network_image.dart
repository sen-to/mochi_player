// 【图片资源界面】统一媒体图片的缓存与下载适配入口。
// 功能页面只描述图片展示，不依赖 TMDB 缓存或网络客户端的具体实现。

import 'package:cached_network_image/cached_network_image.dart';
import 'package:mochi_player/core/data/tmdb/tmdb_image_cache_manager.dart';

class MediaNetworkImage extends CachedNetworkImage {
  MediaNetworkImage({
    super.key,
    required super.imageUrl,
    super.width,
    super.height,
    super.fit,
    super.alignment,
    super.placeholder,
    super.errorWidget,
    super.fadeInDuration,
    super.fadeOutDuration,
  }) : super(cacheManager: TmdbImageCacheManager.instance);
}
