// 【行为测试】验证从文件名与目录上下文提取标题、年份、季集和技术信息。
// 测试对象的职责边界：解析结果不直接写库，不执行网络匹配。

import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/features/library/sync/domain/media_filename_parser.dart';
import 'package:mochi_player/features/library/sync/domain/parsed_media_filename.dart';

void main() {
  group('剧集文件名', () {
    final cases = [
      _ExpectedParse(
        '怪奇物语.S05E04.2016.2160p.WEB-DL.Netflix.DV.H.265.DDP.5.1.Atmos-JZMM.mkv',
        title: '怪奇物语',
        year: 2016,
        season: 5,
        episode: 4,
        container: 'mkv',
        height: 2160,
      ),
      _ExpectedParse(
        'Pluribus.S01E02.2160p.ATVP.WEB-DL.DDP5.1.Atmos.DV.H.265.mkv',
        title: 'Pluribus',
        season: 1,
        episode: 2,
        container: 'mkv',
        height: 2160,
      ),
      _ExpectedParse(
        '我的大叔.2018.S01E14.2160p.WEB-DL.High Frame Rate.H.265.AAC.mkv',
        title: '我的大叔',
        year: 2018,
        season: 1,
        episode: 14,
        container: 'mkv',
        height: 2160,
      ),
    ];

    for (final testCase in cases) {
      test('从剧集文件名提取信息：${testCase.fileName}', () {
        final result = MediaFilenameParser.parse(fileName: testCase.fileName);
        _expectParse(result, testCase);
      });
    }
  });

  group('季目录', () {
    final cases = [
      _ExpectedParse('1.mp4', path: '/media/进击的巨人/第一季/1.mp4', title: '进击的巨人', season: 1, episode: 1, container: 'mp4'),
      _ExpectedParse(
        '第3集.mkv',
        path: '/media/进击的巨人/第十二季/第3集.mkv',
        title: '进击的巨人',
        season: 12,
        episode: 3,
        container: 'mkv',
      ),
      _ExpectedParse(
        '第1集.mkv',
        path: '/media/进击的巨人/S01/第1集.mkv',
        title: '进击的巨人',
        season: 1,
        episode: 1,
        container: 'mkv',
      ),
    ];

    for (final testCase in cases) {
      test('从季目录提取归属：${testCase.path}', () {
        final result = MediaFilenameParser.parse(fileName: testCase.fileName, filePath: testCase.path);
        _expectParse(result, testCase);
      });
    }
  });

  test('仅有集号时推断第一季', () {
    final result = MediaFilenameParser.parse(fileName: '01.mp4', filePath: '/media/进击的巨人/01.mp4');

    expect(result.title, '进击的巨人', reason: 'title');
    expect(result.season, 1, reason: 'season');
    expect(result.episode, 1, reason: 'episode');
    expect(result.isEpisode, true, reason: 'isEpisode');
  });

  for (var episode = 1; episode <= 6; episode++) {
    test('带标签集名使用父目录标题：第 $episode 集', () {
      final episodeLabel = episode.toString().padLeft(2, '0');
      final fileName = '【tvzongheba】E$episodeLabel.mkv';
      final result = MediaFilenameParser.parse(fileName: fileName, filePath: '/dav/quark/来自：分享/街头餐厅斗士/$fileName');

      expect(result.title, '街头餐厅斗士', reason: 'title');
      expect(result.season, 1, reason: 'season');
      expect(result.episode, episode, reason: 'episode');
      expect(result.isEpisode, true, reason: 'isEpisode');
    });
  }

  test('从电影父目录提取标题和年份', () {
    final result = MediaFilenameParser.parse(
      fileName: 'movie.mkv',
      filePath: '/media/Movies/Inception (2010)/movie.mkv',
    );

    expect(result.title, 'Inception', reason: 'title');
    expect(result.year, 2010, reason: 'year');
    expect(result.isEpisode, false, reason: 'isEpisode');
  });

  test('短电影名不被技术标签吞掉', () {
    final result = MediaFilenameParser.parse(
      fileName: 'Saw.2004.2160p.BluRay.REMUX.DV.HDR.HEVC.DTS-HD.MA.TrueHD.7.1.Atmos.mkv',
      filePath:
          '/quark/来自：分享/电锯惊魂系列/电锯惊魂1 4K原盘REMUX 杜比视界 内封字幕/Saw.2004.2160p.BluRay.REMUX.DV.HDR.HEVC.DTS-HD.MA.TrueHD.7.1.Atmos.mkv',
    );

    expect(result.title, 'Saw', reason: 'title');
    expect(result.year, 2004, reason: 'year');
    expect(result.height, 2160, reason: 'height');
    expect(result.container, 'mkv', reason: 'container');
    expect(result.isEpisode, false, reason: 'isEpisode');
  });

  test('移除排名前缀并保留中英文标题', () {
    final result = MediaFilenameParser.parse(fileName: 'Top231.月球.Moon.2009.Bluray.1080p.x265.AAC(5.1).GREENOTEA.mkv');

    expect(result.title, '月球 Moon', reason: 'title');
    expect(result.year, 2009, reason: 'year');
  });

  test('解码标题中的 HTML 实体', () {
    final result = MediaFilenameParser.parse(fileName: 'Top224.国王的演讲.The.King&#39;s.Speech.2010.Bluray.1080p.mkv');

    expect(result.title, "国王的演讲 The King's Speech", reason: 'title');
    expect(result.year, 2010, reason: 'year');
  });

  test('移除中文父目录标题前的单字母前缀', () {
    final result = MediaFilenameParser.parse(fileName: 'E01.mkv', filePath: '/资源/R人生切割术/S01/E01.mkv');

    expect(result.title, '人生切割术', reason: 'path title');
    expect(result.season, 1, reason: 'season');
    expect(result.episode, 1, reason: 'episode');
  });

  for (final fileName in ['离职.Severance.S01E04.1080p.H265.mp4', '离职.Severance.S01E04.1080p.H265-官方中字.mp4']) {
    test('技术后缀不误判集号：$fileName', () {
      final result = MediaFilenameParser.parse(fileName: fileName, filePath: '/资源/R人生切割术/S01/$fileName');

      expect(result.title, '离职 Severance', reason: 'title');
      expect(result.season, 1, reason: 'season');
      expect(result.episode, 4, reason: 'episode');
    });
  }
}

void _expectParse(ParsedMediaFilename result, _ExpectedParse expected) {
  expect(result.title, expected.title, reason: 'title');
  expect(result.year, expected.year, reason: 'year');
  expect(result.season, expected.season, reason: 'season');
  expect(result.episode, expected.episode, reason: 'episode');
  expect(result.isEpisode, expected.season != null || expected.episode != null, reason: 'isEpisode');
  expect(result.container, expected.container, reason: 'container');
  expect(result.height, expected.height, reason: 'height');
}

class _ExpectedParse {
  final String fileName;
  final String? path;
  final String title;
  final int? year;
  final int? season;
  final int? episode;
  final String? container;
  final int? height;

  const _ExpectedParse(
    this.fileName, {
    this.path,
    required this.title,
    this.year,
    this.season,
    this.episode,
    this.container,
    this.height,
  });
}
