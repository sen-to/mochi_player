// 【解析结果模型】保存从文件名和目录上下文提取的媒体属性。
// 只描述本地已知信息，不执行解析、网络匹配或数据库写入。

/// 文件名解析结果
///
/// 从文件名中提取的所有信息，用于填充 MediaFile
class ParsedMediaFilename {
  // ===== 基础信息 =====

  /// 解析后的标题（用于 TMDB 搜索）
  final String title;

  /// 年份
  final int? year;

  /// 季号（剧集用）
  final int? season;

  /// 集号（剧集用）
  final int? episode;

  /// 是否为剧集
  final bool isEpisode;

  /// 从路径中提取的 TMDB ID（如 {tmdbid-12345}）
  final String? tmdbId;

  // ===== 技术信息 =====

  /// 容器格式 (mkv, mp4, avi)
  final String? container;

  /// 分辨率标签 (720p, 1080p, 2160p, 4K)
  final String? resolution;

  /// 从分辨率推算的高度像素
  final int? height;

  /// 视频编码 (hevc, h264, x264, x265, av1)
  final String? videoCodec;

  /// 音频编码 (aac, dts, truehd, atmos, flac)
  final String? audioCodec;

  /// 音频声道 (2.0, 5.1, 7.1)
  final String? audioChannels;

  /// 是否 HDR
  final bool isHdr;

  /// HDR 格式 (hdr10, hdr10plus, dolby_vision)
  final String? hdrFormat;

  /// 来源 (bluray, webdl, webrip, hdtv, remux)
  final String? source;

  /// 版本标签（组合的技术信息，如 "1080p BluRay DTS"）
  final String versionLabel;

  const ParsedMediaFilename({
    required this.title,
    this.year,
    this.season,
    this.episode,
    this.isEpisode = false,
    this.tmdbId,
    this.container,
    this.resolution,
    this.height,
    this.videoCodec,
    this.audioCodec,
    this.audioChannels,
    this.isHdr = false,
    this.hdrFormat,
    this.source,
    this.versionLabel = '',
  });

  @override
  String toString() {
    return 'ParsedMediaFilename(title: $title, year: $year, S${season}E$episode, '
        'container: $container, resolution: $resolution, videoCodec: $videoCodec, '
        'audioCodec: $audioCodec, isHdr: $isHdr)';
  }
}
