// 【持久化契约】定义媒体库目录查询、收藏及清库能力。
// 应用状态只依赖此接口，SQL、DO 和 Mapper 由 data 实现负责。

import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/features/library/catalog/application/media_card_vo.dart';

abstract interface class LibraryCatalogRepository {
  Future<void> initialize();
  Stream<int> watchFileCount();
  Stream<List<LibraryItem>> watchTitles({String? kind, String query, bool recent, int limit});
  Stream<LibraryItem?> watchHero();
  Stream<LibraryItem?> watchDetail(LibraryItem item);
  Future<List<MediaFile>> getVersions(LibraryItem item);
  Stream<List<MediaFile>> watchVersions(LibraryItem item);
  Future<MediaFile?> getEpisodeFile(String id);
  Future<List<MediaFile>> getPlaybackQueue(MediaFile file);
  Stream<List<MediaCardVO>> watchFavorites({String query, int limit});
  Stream<List<MediaCardVO>> watchContinueWatching({int limit});
  Future<bool> setFavorite(LibraryItem item, {required bool isFavorite});
  Future<void> clearLibrary();
}
