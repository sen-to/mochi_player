// 【持久化契约】定义媒体库目录查询、收藏及清库能力。
// 应用状态只依赖此接口，SQL、DO 和 Mapper 由 data 实现负责。

import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/features/library/catalog/application/media_card_vo.dart';

/// 逻辑标题类型；剧集标题不同于物理文件的 episode 类型。
enum LibraryTitleKind { movie, tvShow }

/// 读取和修改本地媒体库，不访问网络或接管共享数据库的生命周期。
/// 查询失败由 Future 或 Stream 的错误报告，不用空集合代替读取失败；
/// 空集合表示没有匹配记录，调用方负责取消自己的订阅。
abstract interface class LibraryCatalogRepository {
  /// 准备本地数据库；失败抛出异常，调用方不得将失败视为空媒体库。
  Future<void> initialize();

  /// 订阅物理文件数，包括同一标题的多个文件版本。
  Stream<int> watchFileCount();

  /// 订阅存在关联文件的电影 / 剧集标题，每个标题返回一次。
  /// kind 为电影或剧集标题；null 表示全部类型。
  /// query 匹配规范化后的标题 / 原标题；recent 优先按标题最早关联文件的添加时间倒序，
  /// 然后按搜索相关性及稳定的类型、标题 ID 排序；limit 限制结果前缀长度。
  Stream<List<LibraryItem>> watchTitles({
    LibraryTitleKind? kind,
    String query = '',
    bool recent = false,
    int limit = 100,
  });

  /// 订阅首页推荐标题；按创建数据流时的日期选取，媒体库为空时返回 null。
  Stream<LibraryItem?> watchHero();

  /// 按标题类型和 TMDB ID 订阅详情；剧集按季号、集号组装，标题不存在时返回 null。
  Stream<LibraryItem?> watchDetail(LibraryItem item);

  /// 读取标题关联的全部物理版本，按季号、集号、路径升序；没有版本时返回空列表。
  Future<List<MediaFile>> getVersions(LibraryItem item);

  /// 订阅版本变化，筛选和排序与 getVersions 一致。
  Stream<List<MediaFile>> watchVersions(LibraryItem item);

  /// episodeKey 是本地单集复合键，不是 TMDB ID 或物理文件 ID。
  /// 多个文件对应同一集时选择文件 ID 最小的版本；没有关联文件时返回 null。
  Future<MediaFile?> getEpisodeFile(String episodeKey);

  /// 非剧集只返回传入文件；剧集按剧 TMDB ID 归组，未匹配时按规范化解析标题归组。
  /// 队列按季号、集号、路径升序，保留不同文件版本；传入文件未在结果中时补到首位。
  Future<List<MediaFile>> getPlaybackQueue(MediaFile file);

  /// 订阅收藏卡片，先按逻辑标题去重，再搜索、排序和限制数量。
  /// query 匹配标题 / 原标题，按相关性和代表文件 ID 排序；未匹配文件保留回退卡片。
  Stream<List<MediaCardVO>> watchFavorites({String query = '', int limit = 100});

  /// 订阅续播卡片，按最近观看时间倒序，每个逻辑标题返回一个播放目标。
  /// 未完成单集继续播放，已完成单集选择后续未完成集；没有后续目标的标题不占结果名额。
  Stream<List<MediaCardVO>> watchContinueWatching({int limit = 100});

  /// 批量设置标题关联文件的收藏状态；true 表示至少命中一条文件记录。
  /// false 表示没有关联文件，不表示写入失败；失败会抛出异常。
  Future<bool> setFavorite(LibraryItem item, {required bool isFavorite});

  /// 在同一事务内清空文件索引和电影 / 剧 / 季 / 集元数据，保留媒体源配置与凭据。
  /// 不删除磁盘上的媒体文件，不关闭数据库；失败抛出异常并回滚。
  Future<void> clearLibrary();
}
