import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/features/playback/presentation/controllers/player_playback_controller.dart';

void main() {
  group('PlayerPlaybackController.bufferingIndicatorDelayFor', () {
    test('delays the buffering spinner for local files', () {
      expect(
        PlayerPlaybackController.bufferingIndicatorDelayFor('file:///Users/mochi/Movies/Example.mkv'),
        PlayerPlaybackController.localBufferingIndicatorDelay,
      );
    });

    test('shows the buffering spinner immediately for WebDAV HTTP streams', () {
      expect(
        PlayerPlaybackController.bufferingIndicatorDelayFor('https://dav.example.com/media/Example.mkv'),
        Duration.zero,
      );
    });

    test('delays the buffering spinner for direct SMB streams', () {
      expect(
        PlayerPlaybackController.bufferingIndicatorDelayFor('smb://nas.local/Media/example.mkv'),
        PlayerPlaybackController.localBufferingIndicatorDelay,
      );
    });
  });
}
