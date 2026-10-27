// 【行为测试】验证连接引擎状态、换片、音轨、缓冲和续播提示。
// 测试对象的职责边界：字幕由子入口管理，引擎和目标资源统一归播放会话所有。

import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/features/playback/ui/controllers/player_playback_controller.dart';

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

    test('shows the buffering spinner immediately for SMB loopback HTTP streams', () {
      expect(
        PlayerPlaybackController.bufferingIndicatorDelayFor('http://127.0.0.1:53127/video?token=example'),
        Duration.zero,
      );
    });
  });
}
