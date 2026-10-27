// 【搜索规则】统一标题搜索使用的字符与标点规范化。
// SQL 搜索与候选比较复用同一规范。

/// 数据库搜索与标题排序共享的文本规范化规则。
String normalizeLibrarySearchText(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[\s\u3000._\-:：，。/\\\(\)\[\]【】]+'), '').trim();
