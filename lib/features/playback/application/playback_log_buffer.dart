// 【诊断数据】保留有限条已脱敏的播放日志快照。
// 不保存媒体凭据，不参与播放状态决策。

import 'dart:collection';

import 'package:mochi_player/features/playback/application/playback_engine.dart';

/// 保留有限条、已脱敏的近期播放诊断日志。
class PlaybackLogBuffer {
  static const defaultCapacity = 120;

  final int capacity;
  final ListQueue<String> _entries = ListQueue<String>();

  PlaybackLogBuffer({this.capacity = defaultCapacity}) : assert(capacity > 0);

  void add(PlaybackLog log) {
    if (_entries.length == capacity) {
      _entries.removeFirst();
    }
    _entries.add('[${log.level}][${log.prefix}] ${sanitize(log.text)}');
  }

  List<String> snapshot() => List.unmodifiable(_entries);

  static String sanitize(String text) {
    var sanitized = text.replaceAllMapped(
      RegExp(r'(?:https?|smb)://[^\s]+', caseSensitive: false),
      (match) => _sanitizeUrl(match.group(0)!),
    );
    // 认证方案不限于 Bearer：WebDAV 使用 Basic，其 base64 值同样属于凭据，
    // 因此按已知 scheme 匹配后整体替换，不能只替换 scheme 而保留凭据值。
    // scheme 必须白名单，否则无方案时会把下一行的头名当成方案吞掉。
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'(authorization\s*[:=]\s*)(?:(?:basic|bearer|digest|negotiate|ntlm)\s+)?[^\s,;]+', caseSensitive: false),
      (match) => '${match.group(1)}<redacted>',
    );
    return sanitized;
  }

  static String _sanitizeUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return '<redacted-url>';

    return uri
        .replace(
          userInfo: uri.userInfo.isEmpty ? null : '<redacted>',
          query: uri.hasQuery ? '<redacted>' : null,
          fragment: uri.hasFragment ? '<redacted>' : null,
        )
        .toString();
  }
}
