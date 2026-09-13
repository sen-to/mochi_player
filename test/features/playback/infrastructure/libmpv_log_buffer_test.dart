import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:mochi_player/features/playback/infrastructure/libmpv_log_buffer.dart';

void main() {
  test('keeps only the newest libmpv entries', () {
    final buffer = LibmpvLogBuffer(capacity: 2);

    buffer.add(const PlayerLog(prefix: 'one', level: 'info', text: 'first'));
    buffer.add(const PlayerLog(prefix: 'two', level: 'warn', text: 'second'));
    buffer.add(const PlayerLog(prefix: 'three', level: 'error', text: 'third'));

    expect(buffer.snapshot(), ['[warn][two] second', '[error][three] third']);
  });

  test('redacts credentials and URL query parameters', () {
    const log =
        'Opening https://admin:secret@example.com/video.mkv?token=secret '
        'Authorization: Bearer bearer-secret';

    final sanitized = LibmpvLogBuffer.sanitize(log);

    expect(sanitized, contains('example.com/video.mkv'));
    expect(sanitized, isNot(contains('admin')));
    expect(sanitized, isNot(contains('secret')));
    expect(sanitized, contains('Authorization: <redacted>'));
  });

  test('removes credentials from SMB media URLs', () {
    final sanitized = LibmpvLogBuffer.sanitize('Opening smb://mochi:secret@nas.local/Media/Example.mkv');

    expect(sanitized, contains('smb://%3Credacted%3E@nas.local'));
    expect(sanitized, isNot(contains('secret')));
  });
}
