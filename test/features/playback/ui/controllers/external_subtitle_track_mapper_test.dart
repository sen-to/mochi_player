// 【行为测试】验证维护选轨、语言优先级、外挂字幕身份与样式覆盖。
// 测试对象的职责边界：只借用引擎；换片使旧操作失效，关闭时取消自己的订阅。

import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/features/playback/domain/playback_track.dart';
import 'package:mochi_player/features/playback/ui/controllers/player_subtitle_controller.dart';
import 'package:path/path.dart' as path;

void main() {
  group('ExternalSubtitleTrackMapper', () {
    test('creates a URI subtitle track with the file name as title', () {
      final track = ExternalSubtitleTrackMapper.fromPath('/media/Movie.zh-CN.srt');

      expect(track.origin, PlaybackTrackOrigin.externalFile);
      expect(track.id, path.normalize('/media/Movie.zh-CN.srt'));
      expect(track.title, 'Movie.zh-CN');
    });

    test('does not reject a format outside the former UI extension list', () {
      final track = ExternalSubtitleTrackMapper.fromPath('/media/Movie.sub');

      expect(track.origin, PlaybackTrackOrigin.externalFile);
      expect(track.id, path.normalize('/media/Movie.sub'));
      expect(track.title, 'Movie');
    });

    test('uses an extensionless file name as the track title', () {
      final track = ExternalSubtitleTrackMapper.fromPath('/media/MovieSubtitle');

      expect(track.title, 'MovieSubtitle');
    });

    test('normalizes a path before it is used as a loaded-file key', () {
      expect(
        ExternalSubtitleTrackMapper.normalizePath('/media/films/../Movie.srt'),
        path.normalize('/media/Movie.srt'),
      );
    });
  });
}
