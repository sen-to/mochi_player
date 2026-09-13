import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/media/media_file_kind.dart';

void main() {
  group('MediaFileKindResolver', () {
    test('distinguishes directories, videos, and unsupported files', () {
      expect(MediaFileKindResolver.resolve('Movies', isDirectory: true), MediaFileKind.directory);
      expect(MediaFileKindResolver.resolve('movie.4K.MKV'), MediaFileKind.video);
      expect(MediaFileKindResolver.resolve('soundtrack.flac'), MediaFileKind.other);
      expect(MediaFileKindResolver.resolve('readme.txt'), MediaFileKind.other);
    });

    test('extracts extensions safely', () {
      expect(MediaFileKindResolver.extensionOf('movie.mp4'), 'mp4');
      expect(MediaFileKindResolver.extensionOf('README'), '');
      expect(MediaFileKindResolver.extensionOf('.hidden'), 'hidden');
    });
  });
}
