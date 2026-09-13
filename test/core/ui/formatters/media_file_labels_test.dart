import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/ui/formatters/media_file_labels.dart';

void main() {
  test('builds one canonical version title and subtitle', () {
    final file = MediaFile(
      id: 1,
      path: '/media/item.mkv',
      fileName: 'item.mkv',
      parsedTitle: 'Item',
      size: 1024 * 1024 * 1024,
      duration: 100000,
      position: 25000,
      height: 2160,
      videoCodec: 'hevc',
      audioCodec: 'eac3',
      audioChannels: '5.1',
      container: 'mkv',
      isHdr: true,
      hdrFormat: 'HDR10',
      versionLabel: '4K BluRay HEVC HDR10 EAC3',
      addedAt: DateTime(2026),
    );

    expect(MediaFileLabels.versionTitle(file), '4K BluRay HEVC HDR10 EAC3');
    expect(
      MediaFileLabels.versionSubtitle(file, includeResumePosition: true),
      'eac3 • 5.1 • MKV • 1.00 GB • 从 00:25 继续',
    );
    expect(MediaFileLabels.playableVersionTitle(file), '4K BluRay');
    expect(MediaFileLabels.playableVersionDetails(file), 'HEVC HDR10 · EAC3 5.1 · MKV · 1.00 GB');
  });
}
