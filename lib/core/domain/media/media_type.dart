// 【共享模型】区分电影、单集、目录及未知媒体类型。
// 用于索引、查询与播放选择。

/// 媒体类型 (Domain layer)
enum MediaType { movie, episode, folder, unknown }
