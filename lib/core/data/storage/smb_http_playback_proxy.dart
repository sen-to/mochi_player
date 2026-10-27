// 【协议资源】将单个 SMB 文件通过带令牌的回环 HTTP Range 服务输出。
// 负责范围、背压、取消及并发传输，关闭时释放读取资源。

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:mochi_player/core/data/storage/smb_media_reader.dart';
import 'package:mochi_player/core/domain/playback/playback_target.dart';

/// 仅监听回环地址、受令牌保护的单文件 HTTP 资源。
class SmbHttpPlaybackProxy implements PlaybackTargetResource {
  SmbHttpPlaybackProxy._(this._server, this._reader, this._token);

  final HttpServer _server;
  final SmbMediaReader _reader;
  final String _token;
  final Map<HttpResponse, _HttpTransfer> _transfers = {};
  Future<void>? _closing;
  static const _chunkSize = 256 * 1024;
  static const _ioTimeout = Duration(seconds: 12);

  Uri get uri =>
      Uri(scheme: 'http', host: '127.0.0.1', port: _server.port, path: '/video', queryParameters: {'token': _token});

  /// 接管 [reader] 的所有权；服务器绑定失败时也必须释放它。
  static Future<SmbHttpPlaybackProxy> start(SmbMediaReader reader) async {
    try {
      if (reader.length < 0) throw StateError('Invalid SMB file length');
      final random = Random.secure();
      final token = base64Url.encode(List.generate(32, (_) => random.nextInt(256))).replaceAll('=', '');
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.idleTimeout = const Duration(seconds: 15);
      // 播放日志会脱敏查询参数，但保留 URL 路径，因此令牌只能放在查询参数中。
      final proxy = SmbHttpPlaybackProxy._(server, reader, token);
      server.listen((request) => unawaited(proxy._serve(request)), onError: (Object _) {});
      return proxy;
    } catch (_) {
      await reader.close();
      rethrow;
    }
  }

  Future<void> _serve(HttpRequest request) async {
    final response = request.response;
    final transfer = _HttpTransfer(response);
    void finished() {
      transfer.cancelled = true;
      _transfers.remove(response);
    }

    unawaited(response.done.then<void>((_) => finished(), onError: (Object _, StackTrace _) => finished()));
    var streaming = false;
    try {
      // 不接受用户任意路径、重定向、跨域访问或任意 Host。
      if (_closing != null ||
          request.uri.path != '/video' ||
          request.uri.queryParameters['token'] != _token ||
          request.headers.value(HttpHeaders.hostHeader) != uri.authority) {
        response.statusCode = HttpStatus.notFound;
        return;
      }
      if (request.method != 'GET' && request.method != 'HEAD') {
        response.statusCode = HttpStatus.methodNotAllowed;
        response.headers.set(HttpHeaders.allowHeader, 'GET, HEAD');
        return;
      }
      response.headers
        ..contentType = ContentType.binary
        ..set(HttpHeaders.acceptRangesHeader, 'bytes')
        ..set(HttpHeaders.cacheControlHeader, 'no-store');
      final size = _reader.length;
      // HEAD 忽略 Range；缺少匹配校验信息时，If-Range 回退到完整内容，避免返回过期字节范围。
      final range = request.method == 'GET' && request.headers.value(HttpHeaders.ifRangeHeader) == null
          ? _ByteRange.parse(request.headers.value(HttpHeaders.rangeHeader), size)
          : null;
      if (range != null && range.start >= size) {
        response.statusCode = HttpStatus.requestedRangeNotSatisfiable;
        response.headers.set(HttpHeaders.contentRangeHeader, 'bytes */$size');
        response.contentLength = 0;
        return;
      }
      var offset = range?.start ?? 0;
      final end = range?.end ?? size - 1;
      response.statusCode = range == null ? HttpStatus.ok : HttpStatus.partialContent;
      response.contentLength = end - offset + 1;
      if (range != null) response.headers.set(HttpHeaders.contentRangeHeader, 'bytes $offset-$end/$size');
      if (request.method == 'HEAD') return;
      // 快速跳转时，客户端可能已放弃连接而 SMB 读取仍未结束，单靠 HttpResponse.done 无法及时发现。达到并发上限时淘汰最旧传输，不能用 503 拒绝最新跳转。
      if (_transfers.length >= 4) {
        final oldest = _transfers.values.first;
        _transfers.remove(oldest.response);
        oldest.cancel();
      }
      _transfers[response] = transfer;
      while (offset <= end && !transfer.cancelled && _closing == null) {
        final wanted = min(_chunkSize, end - offset + 1);
        final bytes = await _reader
            .read(offset, wanted, isCancelled: () => transfer.cancelled || _closing != null)
            .timeout(_ioTimeout);
        if (transfer.cancelled || _closing != null) return;
        if (bytes.isEmpty || bytes.length > wanted) throw StateError('Unexpected SMB read length');
        streaming = true;
        response.add(bytes);
        // 背压限制缓冲占用，并帮助发现已经放弃的跳转请求。
        await response.flush().timeout(_ioTimeout);
        offset += bytes.length;
      }
    } catch (_) {
      if (transfer.cancelled || _closing != null) return;
      // Future.timeout 不会取消底层排队的 SMB 操作；返回错误前先标记过期，防止之后才开始读取。
      transfer.cancelled = true;
      // HTTP 错误和日志不得暴露 NAS 路径、凭据或令牌。
      try {
        if (streaming) {
          (await response.detachSocket(writeHeaders: false)).destroy();
        } else {
          response.statusCode = HttpStatus.badGateway;
          response.contentLength = 0;
          response.headers.removeAll(HttpHeaders.contentRangeHeader);
        }
      } catch (_) {
        // 播放器可能已因跳转或关闭而断开连接。
      }
    } finally {
      _transfers.remove(response);
      try {
        await response.close().timeout(_ioTimeout);
      } catch (_) {
        // 已断开的套接字不能产生未处理的异步错误。
      }
    }
  }

  @override
  Future<void> close() => _closing ??= _close();

  Future<void> _close() async {
    // 先终止 HTTP 连接，再关闭 SMB，防止新读取继续排队。
    try {
      for (final transfer in _transfers.values.toList()) {
        transfer.cancel();
      }
      _transfers.clear();
      await _server.close(force: true);
    } finally {
      await _reader.close();
    }
  }
}

class _HttpTransfer {
  _HttpTransfer(this.response);
  final HttpResponse response;
  bool cancelled = false;

  void cancel() {
    if (cancelled) return;
    cancelled = true;
    unawaited(() async {
      try {
        (await response.detachSocket(writeHeaders: false)).destroy();
      } catch (_) {
        // 连接可能已断开，或已被请求处理器关闭。
      }
    }());
  }
}

class _ByteRange {
  const _ByteRange(this.start, this.end);
  final int start;
  final int end;

  static _ByteRange? parse(String? header, int size) {
    if (header == null) return null;
    // 无效、非字节单位或多段范围请求回退为完整响应；HTTP 允许这样处理，也能避免多段内容缓冲。
    final match = RegExp(r'^bytes=(\d*)-(\d*)$').firstMatch(header.trim());
    if (match == null) return null;
    final first = match[1]!;
    final last = match[2]!;
    if (first.isEmpty && last.isEmpty) return null;
    if (first.isEmpty) {
      final suffix = int.tryParse(last);
      if (suffix == null) return null;
      if (suffix == 0 || size == 0) return _ByteRange(size, size - 1);
      return _ByteRange(max(0, size - suffix), size - 1);
    }
    final start = int.tryParse(first);
    final end = last.isEmpty ? size - 1 : int.tryParse(last);
    if (start == null || end == null) return null;
    if (last.isNotEmpty && end < start) return null;
    return _ByteRange(start, min(end, size - 1));
  }
}
