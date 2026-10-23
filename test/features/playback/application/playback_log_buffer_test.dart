import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/features/playback/application/playback_engine.dart';
import 'package:mochi_player/features/playback/application/playback_log_buffer.dart';

void main() {
  test('redacts loopback playback session tokens', () {
    final sanitized = PlaybackLogBuffer.sanitize('Opening http://127.0.0.1:53127/video?token=session-secret');
    expect(sanitized, contains('127.0.0.1:53127/video'));
    expect(sanitized, isNot(contains('session-secret')));
  });

  test('keeps only the newest libmpv entries', () {
    final buffer = PlaybackLogBuffer(capacity: 2);

    buffer.add(const PlaybackLog(prefix: 'one', level: 'info', text: 'first'));
    buffer.add(const PlaybackLog(prefix: 'two', level: 'warn', text: 'second'));
    buffer.add(const PlaybackLog(prefix: 'three', level: 'error', text: 'third'));

    expect(buffer.snapshot(), ['[warn][two] second', '[error][three] third']);
  });

  test('redacts credentials and URL query parameters', () {
    const log =
        'Opening https://admin:secret@example.com/video.mkv?token=secret '
        'Authorization: Bearer bearer-secret';

    final sanitized = PlaybackLogBuffer.sanitize(log);

    expect(sanitized, contains('example.com/video.mkv'));
    expect(sanitized, isNot(contains('admin')));
    expect(sanitized, isNot(contains('secret')));
    expect(sanitized, contains('Authorization: <redacted>'));
  });

  test('removes credentials from SMB media URLs', () {
    final sanitized = PlaybackLogBuffer.sanitize('Opening smb://mochi:secret@nas.local/Media/Example.mkv');

    expect(sanitized, contains('smb://%3Credacted%3E@nas.local'));
    expect(sanitized, isNot(contains('secret')));
  });
}
