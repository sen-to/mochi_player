// 【行为测试】验证安装项目所需的多视图绑定及 Windows 语义树规避。
// 测试对象的职责边界：平台限制与移除条件见构建文档，不在业务页面中处理。

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/app/bootstrap/mochi_widgets_binding.dart';

void main() {
  final binding = MochiWidgetsBinding();

  test('Windows ignores semantics requests while macOS keeps framework behavior', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final handle = binding.ensureSemantics();
    try {
      expect(binding.semanticsEnabled, isFalse);
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      expect(binding.semanticsEnabled, isTrue);
    } finally {
      handle.dispose();
      debugDefaultTargetPlatformOverride = null;
    }
    expect(binding.semanticsEnabled, isFalse);
  });
}
