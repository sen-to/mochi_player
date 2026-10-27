// 【行为测试】验证根据扩展名区分目录、视频和其他条目。
// 测试对象的职责边界：文件浏览与扫描复用，不负责元数据匹配。

import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/features/library/domain/media_file_kind.dart';

void main() {
  group('MediaFileClassifier', () {
    test('distinguishes directories, videos, and unsupported files', () {
      expect(MediaFileClassifier.resolve('Movies', isDirectory: true), MediaFileKind.directory);
      expect(MediaFileClassifier.resolve('movie.4K.MKV'), MediaFileKind.video);
      expect(MediaFileClassifier.resolve('soundtrack.flac'), MediaFileKind.other);
      expect(MediaFileClassifier.resolve('readme.txt'), MediaFileKind.other);
    });

    test('extracts extensions safely', () {
      expect(MediaFileClassifier.extensionOf('movie.mp4'), 'mp4');
      expect(MediaFileClassifier.extensionOf('README'), '');
      expect(MediaFileClassifier.extensionOf('.hidden'), 'hidden');
    });
  });
}
