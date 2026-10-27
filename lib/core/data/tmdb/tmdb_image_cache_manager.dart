// 【图片基础设施】统一图片下载、磁盘缓存与代理配置。
// 供多个界面复用，界面不为每张图片单独创建缓存。

import 'dart:async';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:mochi_player/core/data/tmdb/http_proxy_parser.dart';

class TmdbImageCacheManager {
  TmdbImageCacheManager._();

  static final _fileService = _TmdbImageFileService();

  static final CacheManager instance = CacheManager(
    Config(
      'tmdbImageCache',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 1200,
      fileService: _fileService,
    ),
  );

  static void configure({required String proxyUrl, required bool proxyEnabled}) {
    _fileService.configure(proxyUrl: proxyUrl, proxyEnabled: proxyEnabled);
  }
}

class _TmdbImageFileService extends FileService {
  _TmdbImageFileService() {
    concurrentFetches = 4;
    _resetClient();
  }

  String _proxyUrl = '';
  bool _proxyEnabled = false;
  late HttpClient _client;

  void configure({required String proxyUrl, required bool proxyEnabled}) {
    final nextProxyUrl = proxyUrl.trim();
    if (_proxyUrl == nextProxyUrl && _proxyEnabled == proxyEnabled) return;

    _proxyUrl = nextProxyUrl;
    _proxyEnabled = proxyEnabled;
    _resetClient();
  }

  void _resetClient() {
    try {
      _client.close(force: false);
    } catch (_) {
      // 首次初始化到达这里时，内部客户端尚未创建。
    }

    final proxyConfig = _proxyEnabled ? HttpProxyParser.buildHttpProxy(_proxyUrl) : null;
    _client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 8)
      ..findProxy = (uri) => proxyConfig ?? 'DIRECT';
  }

  @override
  Future<FileServiceResponse> get(String url, {Map<String, String>? headers}) async {
    final uri = Uri.parse(url);
    final request = await _client.getUrl(uri);
    headers?.forEach(request.headers.set);
    final response = await request.close();
    return _TmdbImageResponse(uri, response);
  }
}

class _TmdbImageResponse implements FileServiceResponse {
  _TmdbImageResponse(this._uri, this._response) : _receivedTime = DateTime.now();

  final Uri _uri;
  final HttpClientResponse _response;
  final DateTime _receivedTime;

  @override
  Stream<List<int>> get content => _response;

  @override
  int? get contentLength => _response.contentLength >= 0 ? _response.contentLength : null;

  @override
  int get statusCode => _response.statusCode;

  @override
  DateTime get validTill {
    var ageDuration = const Duration(days: 7);
    final cacheControl = _response.headers.value(HttpHeaders.cacheControlHeader);
    if (cacheControl != null) {
      for (final setting in cacheControl.split(',')) {
        final value = setting.trim().toLowerCase();
        if (value == 'no-cache') {
          ageDuration = Duration.zero;
        } else if (value.startsWith('max-age=')) {
          final seconds = int.tryParse(value.substring('max-age='.length)) ?? 0;
          if (seconds > 0) ageDuration = Duration(seconds: seconds);
        }
      }
    }
    return _receivedTime.add(ageDuration);
  }

  @override
  String? get eTag => _response.headers.value(HttpHeaders.etagHeader);

  @override
  String get fileExtension {
    final contentType = _response.headers.value(HttpHeaders.contentTypeHeader);
    if (contentType != null) {
      final mimeType = ContentType.parse(contentType).mimeType.toLowerCase();
      switch (mimeType) {
        case 'image/jpeg':
          return '.jpg';
        case 'image/png':
          return '.png';
        case 'image/webp':
          return '.webp';
      }
    }

    final segment = _uri.pathSegments.isEmpty ? '' : _uri.pathSegments.last;
    final dotIndex = segment.lastIndexOf('.');
    if (dotIndex >= 0 && dotIndex < segment.length - 1) {
      return segment.substring(dotIndex);
    }
    return '';
  }
}
