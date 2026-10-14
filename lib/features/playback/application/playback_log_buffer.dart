import 'dart:collection';

import 'package:mochi_player/features/playback/application/playback_engine.dart';

/// Keeps a bounded, sanitized snapshot of recent playback diagnostics.
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
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'(authorization\s*[:=]\s*)(?:bearer\s+)?([^\s,;]+)', caseSensitive: false),
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
