import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/features/playback/application/external_subtitle_track.dart';
import 'package:path/path.dart' as path;

void main() {
  group('ExternalSubtitleTrack', () {
    test('creates a URI subtitle track with the file name as title', () {
      final track = ExternalSubtitleTrack.fromPath('/media/Movie.zh-CN.srt');

      expect(track.uri, isTrue);
      expect(track.id, path.normalize('/media/Movie.zh-CN.srt'));
      expect(track.title, 'Movie.zh-CN');
    });

    test('does not reject a format outside the former UI extension list', () {
      final track = ExternalSubtitleTrack.fromPath('/media/Movie.sub');

      expect(track.uri, isTrue);
      expect(track.id, path.normalize('/media/Movie.sub'));
      expect(track.title, 'Movie');
    });

    test('uses an extensionless file name as the track title', () {
      final track = ExternalSubtitleTrack.fromPath('/media/MovieSubtitle');

      expect(track.title, 'MovieSubtitle');
    });

    test('normalizes a path before it is used as a loaded-file key', () {
      expect(ExternalSubtitleTrack.normalizePath('/media/films/../Movie.srt'), path.normalize('/media/Movie.srt'));
    });
  });
}
