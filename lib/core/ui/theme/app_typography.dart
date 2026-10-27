// 【主题规格】定义标题、正文和辅助文字的排版。
// 只提供视觉规格，不处理本地化文案。

import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const TextStyle formLabel = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.2);

  static const TextStyle formValue = TextStyle(fontSize: 13, fontWeight: FontWeight.w500);

  static const TextStyle formSupporting = TextStyle(fontSize: 11, fontWeight: FontWeight.w500, height: 1.2);

  static const TextStyle formSuffix = TextStyle(fontSize: 12, fontWeight: FontWeight.w700);

  static const TextStyle formValueEmphasis = TextStyle(fontSize: 13, fontWeight: FontWeight.w800);

  static const TextStyle controlLabel = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1);

  const AppTypography._();
}
