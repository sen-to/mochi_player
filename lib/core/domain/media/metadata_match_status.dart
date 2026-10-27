// 【共享模型】定义媒体文件与元数据的匹配状态。
// 待匹配、成功与未匹配不等同于网络请求失败。

/// 本地文件与服务商元数据的关联状态。
enum MetadataMatchStatus { pending, confirmed, unmatched, ambiguous }
