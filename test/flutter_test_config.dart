// 【测试宿主】在普通测试绑定初始化前隔离实验多窗口宿主能力。
// 只影响测试进程，正式应用仍使用多视图。

// ignore_for_file: implementation_imports, invalid_use_of_internal_member

import 'dart:async';

// 固定 SDK 会先于测试宿主初始化 Win32 多窗口能力，而 flutter_tester 不提供对应原生接口。

// 单元和组件测试注入窗口替身；真实窗口由正式 runner 的多窗口冒烟验证。
import 'package:flutter/src/foundation/_features.dart' show isWindowingEnabled;

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  isWindowingEnabled = false;
  await testMain();
}
