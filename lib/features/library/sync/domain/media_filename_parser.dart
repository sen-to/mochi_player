// 【业务规则】从文件名与目录上下文提取标题、年份、季集和技术信息。
// 解析结果不直接写库，不执行网络匹配。

import 'package:mochi_player/features/library/domain/media_file_kind.dart';
import 'package:mochi_player/features/library/sync/domain/parsed_media_filename.dart';

/// 文件名解析器
///
/// 从视频文件名中提取标题、年份、季集号、技术规格等信息
class MediaFilenameParser {
  // ===== 正则表达式模式 =====

  // 季集号: S01E05, S01.E05, Season 1 Episode 5
  static final _seasonEpisodePattern = RegExp(
    r'(?:^|[.\s_\[\(\]\)【】])(?:S|Season\s?)(\d{1,2})[.\s_]?(?:E|Episode\s?)(\d{1,3})(?:$|[.\s_\]\)【】])?',
    caseSensitive: false,
  );

  // 单季: S01, Season 1, 第一季
  static final _seasonOnlyPattern = RegExp(
    r'(?:^|[.\s_\-\[\(\]\)【】])(?:S|Season\s?)(\d{1,2})(?:季|$|[.\s_\-\]\)【】])',
    caseSensitive: false,
  );

  static final _chineseSeasonPattern = RegExp(r'(?:^|[.\s_\-\[\(\]\)【】])第([一二两三四五六七八九十\d]{1,3})季(?:$|[.\s_\-\]\)【】])?');

  // 单集: E01, EP01, 第1集, 01
  static final _episodeOnlyPattern = RegExp(
    r'(?:^|[.\s_\-\[\(\]\)【】])(?:E|EP|Episode\s?)(\d{1,3})(?:$|[.\s_\-\]\)【】])',
    caseSensitive: false,
  );

  static final _chineseEpisodePattern = RegExp(
    r'(?:^|[.\s_\-\[\(\]\)【】])第?([一二两三四五六七八九十百\d]{1,3})(?:集|话)(?:$|[.\s_\-\]\)【】])?',
  );

  static final _bareEpisodePattern = RegExp(r'^\s*0*(\d{1,3})\s*$');

  // 年份: (2024), .2024., _2024_
  static final _yearPattern = RegExp(r'[.\s_\(\[](\d{4})[.\s_\)\]]');

  // 显式 TMDB 标识格式为 {tmdbid-12345}。
  static final _tmdbIdPattern = RegExp(r'\{tmdb(?:id)?[=-](\d+)\}', caseSensitive: false);

  // 分辨率
  static final _resolutionPattern = RegExp(r'\b(720p|1080p|2160p|4k|uhd)\b', caseSensitive: false);

  // 视频编码
  static final _videoCodecPattern = RegExp(
    r'\b(hevc|h\.?265|x265|h\.?264|x264|avc|av1|vp9|mpeg[24]?)\b',
    caseSensitive: false,
  );

  // 音频编码 (包括带声道的格式如 DDP5.1)
  static final _audioCodecPattern = RegExp(
    r'\b(aac|ac3|eac3|e-ac-3|dts(?:-hd)?(?:-ma)?|truehd|atmos|flac|opus|pcm|lpcm|dd\+?|ddp?)((?:5\.1|7\.1|2\.0)?)?\b',
    caseSensitive: false,
  );

  // 音频声道 (独立的声道标识，如 "5.1" 或 "DTS 5.1")
  static final _audioChannelsPattern = RegExp(r'(?<!\w)(2\.0|5\.1|7\.1|stereo|mono)(?!\d)', caseSensitive: false);

  // HDR 格式
  static final _hdrPattern = RegExp(r'\b(hdr10\+?|hdr|dolby\s?vision|dv|dovi|hlg)\b', caseSensitive: false);

  // 来源
  static final _sourcePattern = RegExp(
    r'\b(bluray|blu-ray|bdrip|brrip|remux|webdl|web-dl|webrip|web|hdtv|dvdrip|hdcam|cam|ts|tc)\b',
    caseSensitive: false,
  );

  /// 解析文件名
  static ParsedMediaFilename parse({required String fileName, String? filePath}) {
    final pathSegments = _pathSegments(filePath);
    final parentSegments = pathSegments.isNotEmpty
        ? pathSegments.take(pathSegments.length - 1).toList()
        : const <String>[];
    var seasonContext = _extractSeasonContext(parentSegments);
    final standaloneEpisode = _extractStandaloneEpisodeFromFileName(fileName);
    seasonContext ??= _inferSeasonOneContext(parentSegments, standaloneEpisode);

    // 提取容器格式（扩展名）
    String? container;
    if (fileName.contains('.')) {
      final ext = fileName.split('.').last.toLowerCase();
      if (MediaFileClassifier.isVideoExtension(ext)) {
        container = ext;
      }
    }

    // 提取季集号
    int? season;
    int? episode;
    bool isEpisode = false;
    String nameForTitle = fileName;

    final seMatch = _seasonEpisodePattern.firstMatch(fileName);
    if (seMatch != null) {
      season = int.tryParse(seMatch.group(1)!);
      episode = int.tryParse(seMatch.group(2)!);
      isEpisode = season != null && episode != null;
      nameForTitle = fileName.substring(0, seMatch.start);
    }

    season ??= seasonContext?.season;
    if (season != null) {
      episode ??= _extractEpisodeFromFileName(fileName);
    }
    if (season != null && episode != null) {
      isEpisode = true;
    }

    // 提取年份
    int? year;
    for (final match in _yearPattern.allMatches(fileName)) {
      final y = int.parse(match.group(1)!);
      if (y >= 1900 && y <= 2100) {
        year = y;
        // 如果年份在标题区域内，更新标题截取位置
        if (match.start < nameForTitle.length) {
          nameForTitle = fileName.substring(0, match.start);
        }
        break;
      }
    }
    year ??= _extractYearFromPath(parentSegments);

    // 清理标题
    final titleSource = _stripExtension(nameForTitle);
    String title = _cleanTitle(titleSource) ?? _stripExtension(fileName).trim();
    if (title.isEmpty) title = fileName;

    final pathTitle =
        _extractTitleFromPath(parentSegments, seasonContext) ?? _extractNearestTitleFromPath(parentSegments);
    if (pathTitle != null && _shouldUsePathTitle(title, fileName, isEpisode, seasonContext)) {
      title = pathTitle;
    }

    // 提取 TMDB ID（从文件路径）
    String? tmdbId;
    if (filePath != null) {
      final tmdbMatch = _tmdbIdPattern.firstMatch(filePath);
      tmdbId = tmdbMatch?.group(1);
    }

    // 提取分辨率
    String? resolution;
    int? height;
    final resMatch = _resolutionPattern.firstMatch(fileName);
    if (resMatch != null) {
      resolution = resMatch.group(1)!.toLowerCase();
      height = _parseResolutionToHeight(resolution);
    }

    // 提取视频编码
    String? videoCodec;
    final videoMatch = _videoCodecPattern.firstMatch(fileName);
    if (videoMatch != null) {
      videoCodec = _normalizeVideoCodec(videoMatch.group(1)!);
    }

    // 提取音频编码和可能嵌入的声道 (如 DDP5.1)
    String? audioCodec;
    String? embeddedChannels;
    final audioMatch = _audioCodecPattern.firstMatch(fileName);
    if (audioMatch != null) {
      audioCodec = _normalizeAudioCodec(audioMatch.group(1)!);
      // 检查是否有嵌入的声道信息 (group 2)
      if (audioMatch.group(2) != null && audioMatch.group(2)!.isNotEmpty) {
        embeddedChannels = audioMatch.group(2)!;
      }
    }

    // 提取音频声道 (独立的或从编码中嵌入的)
    String? audioChannels = embeddedChannels;
    if (audioChannels == null) {
      final channelsMatch = _audioChannelsPattern.firstMatch(fileName);
      if (channelsMatch != null) {
        audioChannels = _normalizeAudioChannels(channelsMatch.group(1)!);
      }
    }

    // 提取 HDR 信息
    bool isHdr = false;
    String? hdrFormat;
    final hdrMatch = _hdrPattern.firstMatch(fileName);
    if (hdrMatch != null) {
      isHdr = true;
      hdrFormat = _normalizeHdrFormat(hdrMatch.group(1)!);
    }

    // 提取来源
    String? source;
    final sourceMatch = _sourcePattern.firstMatch(fileName);
    if (sourceMatch != null) {
      source = _normalizeSource(sourceMatch.group(1)!);
    }

    // 构建版本标签
    final versionLabel = _buildVersionLabel(
      resolution: resolution,
      source: source,
      videoCodec: videoCodec,
      audioCodec: audioCodec,
      hdrFormat: hdrFormat,
    );

    return ParsedMediaFilename(
      title: title,
      year: year,
      season: season,
      episode: episode,
      isEpisode: isEpisode,
      tmdbId: tmdbId,
      container: container,
      resolution: resolution,
      height: height,
      videoCodec: videoCodec,
      audioCodec: audioCodec,
      audioChannels: audioChannels,
      isHdr: isHdr,
      hdrFormat: hdrFormat,
      source: source,
      versionLabel: versionLabel,
    );
  }

  // ===== 辅助方法 =====

  static List<String> _pathSegments(String? filePath) {
    if (filePath == null || filePath.isEmpty) return const [];
    return filePath.split(RegExp(r'[\\/]')).where((segment) => segment.trim().isNotEmpty).toList();
  }

  static _SeasonContext? _extractSeasonContext(List<String> parentSegments) {
    for (var i = parentSegments.length - 1; i >= 0; i--) {
      final segment = parentSegments[i];
      final match = _seasonOnlyPattern.firstMatch(segment);
      if (match != null) {
        return _SeasonContext(
          season: int.parse(match.group(1)!),
          segmentIndex: i,
          titleHint: _cleanTitle(segment.substring(0, match.start)),
        );
      }

      final chineseMatch = _chineseSeasonPattern.firstMatch(segment);
      if (chineseMatch != null) {
        final season = _parseFlexibleNumber(chineseMatch.group(1)!);
        if (season != null) {
          return _SeasonContext(
            season: season,
            segmentIndex: i,
            titleHint: _cleanTitle(segment.substring(0, chineseMatch.start)),
          );
        }
      }
    }
    return null;
  }

  static _SeasonContext? _inferSeasonOneContext(List<String> parentSegments, int? standaloneEpisode) {
    if (standaloneEpisode == null) return null;

    final title = _extractNearestTitleFromPath(parentSegments);
    if (title == null) return null;

    return _SeasonContext(season: 1, segmentIndex: parentSegments.length, titleHint: title);
  }

  static int? _extractEpisodeFromFileName(String fileName) {
    // 这里只接受明确独立的集数标签，不能从任意末尾数字推导集数；H265、x264、1080p 等编码和画质标签都不是集数。
    return _extractStandaloneEpisodeFromFileName(fileName);
  }

  static int? _extractStandaloneEpisodeFromFileName(String fileName) {
    final stem = _stripExtension(fileName);

    final episodeMatch = _episodeOnlyPattern.firstMatch(stem);
    if (episodeMatch != null) {
      return int.tryParse(episodeMatch.group(1)!);
    }

    final chineseMatch = _chineseEpisodePattern.firstMatch(stem);
    if (chineseMatch != null) {
      return _parseFlexibleNumber(chineseMatch.group(1)!);
    }

    final bareMatch = _bareEpisodePattern.firstMatch(stem);
    if (bareMatch != null) {
      return int.tryParse(bareMatch.group(1)!);
    }

    return null;
  }

  static String? _extractTitleFromPath(List<String> parentSegments, _SeasonContext? seasonContext) {
    if (seasonContext == null) return null;

    final titleHint = seasonContext.titleHint;
    if (titleHint != null && titleHint.isNotEmpty) {
      return titleHint;
    }

    for (var i = seasonContext.segmentIndex - 1; i >= 0; i--) {
      final title = _cleanTitle(parentSegments[i]);
      if (title != null && !_isGenericDirectoryName(title)) {
        return title;
      }
    }
    return null;
  }

  static String? _extractNearestTitleFromPath(List<String> parentSegments) {
    for (var i = parentSegments.length - 1; i >= 0; i--) {
      final segment = parentSegments[i];
      if (_isSeasonDirectorySegment(segment)) continue;

      final title = _cleanTitle(segment);
      if (title != null && !_isGenericDirectoryName(title)) {
        return title;
      }
    }
    return null;
  }

  static bool _shouldUsePathTitle(String fileTitle, String fileName, bool isEpisode, _SeasonContext? seasonContext) {
    if (_isGenericFileTitle(fileTitle)) return true;

    if (!isEpisode || seasonContext == null) return false;
    if (fileTitle.trim().isEmpty) return true;
    if (int.tryParse(fileTitle.trim()) != null) return true;
    if (_extractEpisodeFromFileName(fileName) != null) return true;

    return seasonContext.titleHint != null;
  }

  static String _stripExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex <= 0) return fileName;

    final ext = fileName.substring(dotIndex + 1).toLowerCase();
    return MediaFileClassifier.isVideoExtension(ext) ? fileName.substring(0, dotIndex) : fileName;
  }

  static String? _cleanTitle(String value) {
    final separatorCleaned = _removeYearMarkers(
      _decodeHtmlEntities(value),
    ).replaceAll(RegExp(r'[._\[\]]'), ' ').replaceAll(RegExp(r'[\(\)\-]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
    final title = _removeTitleNoise(separatorCleaned);
    return title.isEmpty ? null : title;
  }

  /// 从网页索引复制的文件名可能包含 King&amp;#39;s 一类 HTML 实体；清理标题或查询 TMDB 前先解码。
  static String _decodeHtmlEntities(String value) {
    final numericDecoded = value.replaceAllMapped(RegExp(r'&#(?:x([0-9a-fA-F]+)|(\d+));'), (match) {
      final codePoint = int.tryParse(match.group(1) ?? '', radix: 16) ?? int.tryParse(match.group(2) ?? '');
      if (codePoint == null || codePoint > 0x10ffff) return match.group(0)!;
      return String.fromCharCode(codePoint);
    });
    return numericDecoded
        .replaceAll('&apos;', "'")
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&nbsp;', ' ');
  }

  /// 在解析阶段移除不属于标题的发布标签，让后续流程接收语义标题，避免各元数据服务重复清理。
  static String _removeTitleNoise(String value) {
    return value
        // 部分索引在中文标题前直接添加分类字母，例如 R人生切割术；该字母不属于标题。
        .replaceFirst(RegExp(r'^[A-Za-z](?=[\u4e00-\u9fff\u3400-\u4dbf])'), '')
        .replaceFirst(RegExp(r'^(?:[A-Za-z]\s*)?(?:top\s*0*\d+)\s*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^(?:韩剧|美剧|日剧|英剧|台剧|国产剧|国剧|电视剧)\s*', caseSensitive: false), '')
        .replaceAll(
          RegExp(r'特别加长版|导演剪辑(?:加长)?版|加长版|(?:数码)?修复版|CC标准收藏版|标准收藏版|(?:\d+)?周年纪念版|纪念版', caseSensitive: false),
          ' ',
        )
        .replaceAll(
          RegExp(
            r"\b(?:director(?:'|&#39;)?s cut|extended(?: cut| edition)?|special edition|anniversary edition|criterion collection|remastered|restored|collector(?:'|&#39;)?s edition|ultimate edition|unrated|theatrical cut)\b",
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(RegExp(r'\b(?:720p|1080p|2160p|4k|uhd)\b', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _removeYearMarkers(String value) {
    return value
        .replaceAll(RegExp(r'[\(\[](?:19\d{2}|20\d{2}|2100)[\)\]]'), ' ')
        .replaceAll(RegExp(r'[._\s]+(?:19\d{2}|20\d{2}|2100)(?=$|[._\s])'), ' ');
  }

  static int? _extractYearFromPath(List<String> parentSegments) {
    for (var i = parentSegments.length - 1; i >= 0; i--) {
      final segment = parentSegments[i];
      final match = RegExp(r'(?:^|[.\s_\(\[])(19\d{2}|20\d{2}|2100)(?=$|[.\s_\)\]])').firstMatch(segment);
      if (match != null) {
        return int.tryParse(match.group(1)!);
      }
    }
    return null;
  }

  static bool _isSeasonDirectorySegment(String segment) {
    return _seasonOnlyPattern.hasMatch(segment) || _chineseSeasonPattern.hasMatch(segment);
  }

  static bool _isGenericFileTitle(String title) {
    final normalized = title.toLowerCase().replaceAll(RegExp(r'[\s._\-]+'), '');
    return {
      'movie',
      'film',
      'video',
      'main',
      'feature',
      'featurefilm',
      'play',
      'default',
      'index',
      '正片',
      '影片',
      '电影',
    }.contains(normalized);
  }

  static bool _isGenericDirectoryName(String title) {
    final normalized = title.toLowerCase().replaceAll(' ', '');
    return {
      'tv',
      'tvshows',
      'media',
      'library',
      'video',
      'videos',
      'collection',
      'series',
      'show',
      'shows',
      'anime',
      'animation',
      'season',
      'season1',
      'season01',
      'movie',
      'movies',
      'film',
      'films',
      '剧集',
      '电视剧',
      '动画',
      '动漫',
      '电影',
    }.contains(normalized);
  }

  static int? _parseFlexibleNumber(String value) {
    final numeric = int.tryParse(value);
    if (numeric != null) return numeric;

    return _parseChineseNumber(value);
  }

  static int? _parseChineseNumber(String value) {
    const digits = {'零': 0, '一': 1, '二': 2, '两': 2, '三': 3, '四': 4, '五': 5, '六': 6, '七': 7, '八': 8, '九': 9};

    if (digits.containsKey(value)) return digits[value];
    if (value == '十') return 10;

    final tenIndex = value.indexOf('十');
    if (tenIndex >= 0) {
      final tensText = value.substring(0, tenIndex);
      final onesText = value.substring(tenIndex + 1);
      final tens = tensText.isEmpty ? 1 : digits[tensText];
      final ones = onesText.isEmpty ? 0 : digits[onesText];
      if (tens == null || ones == null) return null;
      return tens * 10 + ones;
    }

    return null;
  }

  static int? _parseResolutionToHeight(String resolution) {
    switch (resolution.toLowerCase()) {
      case '720p':
        return 720;
      case '1080p':
        return 1080;
      case '2160p':
      case '4k':
      case 'uhd':
        return 2160;
      default:
        return null;
    }
  }

  static String _normalizeVideoCodec(String codec) {
    final c = codec.toLowerCase().replaceAll('.', '');
    if (c.contains('265') || c == 'hevc') return 'hevc';
    if (c.contains('264') || c == 'avc') return 'h264';
    if (c == 'av1') return 'av1';
    if (c == 'vp9') return 'vp9';
    return c;
  }

  static String _normalizeAudioCodec(String codec) {
    final c = codec.toLowerCase().replaceAll('-', '').replaceAll(' ', '');
    if (c.contains('truehd')) return 'truehd';
    if (c.contains('atmos')) return 'atmos';
    if (c.contains('dtshd') || c.contains('dtshdma')) return 'dts-hd';
    if (c.contains('dts')) return 'dts';
    if (c.contains('eac3') || c == 'ddp' || c.contains('dd+')) return 'eac3';
    if (c.contains('ac3') || c == 'dd') return 'ac3';
    if (c == 'aac') return 'aac';
    if (c == 'flac') return 'flac';
    if (c == 'opus') return 'opus';
    return c;
  }

  static String _normalizeAudioChannels(String channels) {
    final c = channels.toLowerCase();
    if (c == 'stereo') return '2.0';
    if (c == 'mono') return '1.0';
    return c; // 2.0, 5.1, 7.1
  }

  static String _normalizeHdrFormat(String hdr) {
    final h = hdr.toLowerCase().replaceAll(' ', '');
    if (h.contains('dolbyvision') || h == 'dv' || h == 'dovi') {
      return 'dolby_vision';
    }
    if (h.contains('hdr10+') || h == 'hdr10plus') return 'hdr10plus';
    if (h == 'hdr10') return 'hdr10';
    if (h == 'hdr') return 'hdr';
    if (h == 'hlg') return 'hlg';
    return h;
  }

  static String _normalizeSource(String source) {
    final s = source.toLowerCase().replaceAll('-', '');
    if (s.contains('bluray') || s == 'bdrip' || s == 'brrip') return 'bluray';
    if (s == 'remux') return 'remux';
    if (s.contains('webdl')) return 'webdl';
    if (s.contains('webrip') || s == 'web') return 'webrip';
    if (s == 'hdtv') return 'hdtv';
    if (s.contains('dvd')) return 'dvdrip';
    return s;
  }

  static String _buildVersionLabel({
    String? resolution,
    String? source,
    String? videoCodec,
    String? audioCodec,
    String? hdrFormat,
  }) {
    final parts = <String>[];
    if (resolution != null) parts.add(resolution.toUpperCase());
    if (source != null) parts.add(_formatSource(source));
    if (videoCodec != null) parts.add(videoCodec.toUpperCase());
    if (hdrFormat != null) parts.add(_formatHdr(hdrFormat));
    if (audioCodec != null) parts.add(audioCodec.toUpperCase());
    return parts.join(' ');
  }

  static String _formatSource(String source) {
    switch (source) {
      case 'bluray':
        return 'BluRay';
      case 'remux':
        return 'REMUX';
      case 'webdl':
        return 'WEB-DL';
      case 'webrip':
        return 'WEBRip';
      default:
        return source.toUpperCase();
    }
  }

  static String _formatHdr(String hdr) {
    switch (hdr) {
      case 'dolby_vision':
        return 'DV';
      case 'hdr10plus':
        return 'HDR10+';
      case 'hdr10':
        return 'HDR10';
      default:
        return hdr.toUpperCase();
    }
  }
}

class _SeasonContext {
  final int season;
  final int segmentIndex;
  final String? titleHint;

  const _SeasonContext({required this.season, required this.segmentIndex, required this.titleHint});
}
