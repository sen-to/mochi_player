import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:mochi_player/core/domain/playback/playback_target.dart';
import 'package:mochi_player/core/infrastructure/storage/smb_media_reader.dart';

/// A loopback-only, token-protected HTTP resource for exactly one SMB file.
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

  /// Takes ownership of [reader], including when binding the server fails.
  static Future<SmbHttpPlaybackProxy> start(SmbMediaReader reader) async {
    try {
      if (reader.length < 0) throw StateError('Invalid SMB file length');
      final random = Random.secure();
      final token = base64Url.encode(List.generate(32, (_) => random.nextInt(256))).replaceAll('=', '');
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.idleTimeout = const Duration(seconds: 15);
      // Playback logging redacts query strings, but preserves URL paths.
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
      // Never accept a user-selected path, redirects, CORS, or arbitrary Host.
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
      // HEAD ignores Range. Without a matching validator, If-Range requests
      // fall back to the complete representation rather than stale byte data.
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
      // During rapid seeks, a client can abandon its socket while its SMB read
      // is still pending. HttpResponse.done alone does not reliably observe
      // that until the next write. Never reject the newest seek with 503:
      // bound active streams by evicting the oldest transfer instead.
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
        // Backpressure bounds buffering and detects abandoned seek requests.
        await response.flush().timeout(_ioTimeout);
        offset += bytes.length;
      }
    } catch (_) {
      if (transfer.cancelled || _closing != null) return;
      // Future.timeout does not cancel an SMB operation queued underneath it.
      // Mark it obsolete before sending an error so it cannot start later.
      transfer.cancelled = true;
      // Do not expose NAS paths, credentials, or tokens in HTTP errors/logs.
      try {
        if (streaming) {
          (await response.detachSocket(writeHeaders: false)).destroy();
        } else {
          response.statusCode = HttpStatus.badGateway;
          response.contentLength = 0;
          response.headers.removeAll(HttpHeaders.contentRangeHeader);
        }
      } catch (_) {
        // The player may have already disconnected after a seek or close.
      }
    } finally {
      _transfers.remove(response);
      try {
        await response.close().timeout(_ioTimeout);
      } catch (_) {
        // A disconnected socket must not become an unhandled async error.
      }
    }
  }

  @override
  Future<void> close() => _closing ??= _close();

  Future<void> _close() async {
    // Kill HTTP connections before closing SMB so no new read can be queued.
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
        // Already disconnected or closed by the request handler.
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
    // Ignore malformed, unsupported-unit and multipart ranges: returning the
    // full representation is allowed by HTTP and avoids multipart buffering.
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
