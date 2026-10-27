// 【平台初始化】安装项目所需的多视图绑定及 Windows 语义树规避。
// 平台限制与移除条件见构建文档，不在业务页面中处理。

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// 针对 flutter/flutter#175041 的 Windows 临时规避；原生 AXTree 崩溃修复并验收前，禁止共享引擎为任何视图生成语义更新，其他平台保持默认行为。
class MochiWidgetsBinding extends WidgetsFlutterBinding {
  @override
  bool get semanticsEnabled {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) return false;
    return super.semanticsEnabled;
  }
}
