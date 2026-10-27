// 【共享模型】定义未开始、观看中和已完成的观看状态。
// 状态推导由观看进度规则负责。

/// 观看状态 (Domain layer)
enum WatchStatus { notStarted, watching, completed }
