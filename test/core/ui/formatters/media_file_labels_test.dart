// 【行为测试】验证根据媒体文件生成版本名称、编码、分辨率和观看信息。
// 测试对象的职责边界：只生成本地化展示文本，不读取数据库或修改文件记录。

import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/ui/formatters/media_file_labels.dart';
import 'package:mochi_player/l10n/generated/app_localizations_zh.dart';

void main() {
  test('版本选择保留完整标签，详情列表将技术信息移入副标题', () {
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

    expect(MediaFileLabels.selectionVersionTitle(file), '4K BluRay HEVC HDR10 EAC3');
    expect(
      MediaFileLabels.selectionVersionSubtitle(file, l10n: AppLocalizationsZh(), includeResumePosition: true),
      'eac3 • 5.1 • MKV • 1.00 GB • 从 00:25 继续',
    );
    expect(MediaFileLabels.detailVersionTitle(file), '4K BluRay');
    expect(
      MediaFileLabels.detailVersionSubtitle(file, l10n: AppLocalizationsZh()),
      'HEVC HDR10 · EAC3 5.1 · MKV · 1.00 GB',
    );
  });
}
