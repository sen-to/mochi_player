import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/infrastructure/storage/smb_http_playback_proxy.dart';

import 'smb_media_reader_fake.dart';

void main() {
  late HttpClient client;
  late MemorySmbReader reader;
  late SmbHttpPlaybackProxy proxy;

  setUp(() async {
    client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
    reader = MemorySmbReader(Uint8List.fromList(List.generate(100, (i) => i)));
    proxy = await SmbHttpPlaybackProxy.start(reader);
  });
  tearDown(() async {
    client.close(force: true);
    await proxy.close();
  });

  Future<HttpClientResponse> request({String method = 'GET', String? range, Uri? uri, String? ifRange}) async {
    final request = await client.openUrl(method, uri ?? proxy.uri);
    if (range != null) request.headers.set(HttpHeaders.rangeHeader, range);
    if (ifRange != null) request.headers.set(HttpHeaders.ifRangeHeader, ifRange);
    return request.close();
  }

  test('loopback URL is private and HEAD reports size without reading SMB', () async {
    expect(proxy.uri.host, '127.0.0.1');
    expect(proxy.uri.port, greaterThan(0));
    expect(proxy.uri.queryParameters['token']!.length, greaterThanOrEqualTo(43));
    final response = await request(method: 'HEAD', range: 'bytes=40-49');
    expect(response.statusCode, 200);
    expect(response.contentLength, 100);
    expect(response.headers.value(HttpHeaders.acceptRangesHeader), 'bytes');
    expect(await response.toList(), isEmpty);
    expect(reader.reads, isEmpty);
  });

  test('GET streams the entire file', () async {
    final response = await request();
    expect(response.statusCode, 200);
    expect(await response.expand((chunk) => chunk).toList(), reader.bytes);
  });

  for (final (header, start, end) in [
    ('bytes=20-29', 20, 29),
    ('bytes=90-', 90, 99),
    ('bytes=-8', 92, 99),
    ('bytes=95-999', 95, 99),
    ('bytes=-999', 0, 99),
    ('bytes=0-0', 0, 0),
  ]) {
    test('serves $header at the requested SMB offset', () async {
      final response = await request(range: header);
      expect(response.statusCode, 206);
      expect(response.headers.value(HttpHeaders.contentRangeHeader), 'bytes $start-$end/100');
      expect(response.contentLength, end - start + 1);
      expect(await response.expand((chunk) => chunk).toList(), reader.bytes.sublist(start, end + 1));
      expect(reader.reads.first.$1, start);
    });
  }

  for (final header in ['bytes=100-', 'bytes=1000-2000', 'bytes=-0']) {
    test('rejects unsatisfiable $header without an SMB read', () async {
      final response = await request(range: header);
      expect(response.statusCode, 416);
      expect(response.headers.value(HttpHeaders.contentRangeHeader), 'bytes */100');
      await response.drain<void>();
      expect(reader.reads, isEmpty);
    });
  }

  for (final header in ['bytes=8-2', 'bytes=foo', 'items=0-2', 'bytes=0-1,5-6']) {
    test('ignores unsupported or malformed $header', () async {
      final response = await request(range: header);
      expect(response.statusCode, 200);
      expect(await response.expand((chunk) => chunk).toList(), reader.bytes);
    });
  }

  test('If-Range without a matching validator falls back to full GET', () async {
    final response = await request(range: 'bytes=2-3', ifRange: '"unknown"');
    expect(response.statusCode, 200);
    expect(await response.expand((chunk) => chunk).toList(), reader.bytes);
  });

  test('wrong token, arbitrary file paths and unsupported methods cannot read SMB', () async {
    for (final query in ['', 'token=wrong']) {
      final response = await request(uri: proxy.uri.replace(query: query));
      expect(response.statusCode, 404);
      await response.drain<void>();
    }
    for (final path in ['/wrong/video', '${proxy.uri.path}/other.mkv', '/etc/passwd']) {
      final response = await request(uri: proxy.uri.replace(path: path));
      expect(response.statusCode, 404);
      await response.drain<void>();
    }
    final response = await request(method: 'POST');
    expect(response.statusCode, 405);
    await response.drain<void>();
    expect(reader.reads, isEmpty);
  });

  test('sessions get independent secrets and reject foreign Host headers', () async {
    final other = await SmbHttpPlaybackProxy.start(MemorySmbReader(Uint8List(1)));
    addTearDown(other.close);
    expect(other.uri.queryParameters['token'], isNot(proxy.uri.queryParameters['token']));
    final request = await client.getUrl(proxy.uri);
    request.headers.set(HttpHeaders.hostHeader, 'untrusted.example');
    final response = await request.close();
    expect(response.statusCode, 404);
    await response.drain<void>();
    expect(reader.reads, isEmpty);
  });

  test('replaces the oldest transfer instead of rejecting the newest seek', () async {
    await proxy.close();
    final started = Completer<void>();
    final gate = Completer<void>();
    var reads = 0;
    reader = MemorySmbReader(
      Uint8List(10),
      beforeRead: () {
        if (++reads == 4) started.complete();
        return gate.future;
      },
    );
    proxy = await SmbHttpPlaybackProxy.start(reader);
    final oldest = request();
    final oldestClosed = expectLater(oldest, throwsA(isA<HttpException>()));
    final pending = List.generate(3, (_) => request());
    Future<HttpClientResponse>? newest;
    try {
      await started.future;
      newest = request(range: 'bytes=2-3');
      await Future<void>.delayed(const Duration(milliseconds: 10));
    } finally {
      gate.complete();
      await oldestClosed;
      for (final response in await Future.wait(pending)) {
        await response.drain<void>();
      }
    }
    final replacement = await newest;
    expect(replacement.statusCode, 206);
    expect(await replacement.expand((chunk) => chunk).toList(), [0, 0]);
    final response = await request();
    expect(response.statusCode, 200);
    await response.drain<void>();
  });

  test('concurrent ranges have independent offsets', () async {
    final bodies = await Future.wait(
      [10, 30, 70].map((start) async {
        final response = await request(range: 'bytes=$start-${start + 4}');
        expect(response.statusCode, 206);
        return response.expand((chunk) => chunk).toList();
      }),
    );
    expect(bodies, [reader.bytes.sublist(10, 15), reader.bytes.sublist(30, 35), reader.bytes.sublist(70, 75)]);
  });

  test('rapid abandoned ranges cannot reject the latest seek', () async {
    await proxy.close();
    final gate = Completer<void>();
    reader = MemorySmbReader(Uint8List(100), beforeRead: () => gate.future);
    proxy = await SmbHttpPlaybackProxy.start(reader);
    final sockets = <Socket>[];
    try {
      for (var i = 0; i < 8; i++) {
        final socket = await Socket.connect(proxy.uri.host, proxy.uri.port);
        sockets.add(socket);
        socket.write(
          'GET ${proxy.uri.path}?${proxy.uri.query} HTTP/1.1\r\n'
          'Host: ${proxy.uri.authority}\r\nRange: bytes=$i-\r\n\r\n',
        );
        await socket.flush();
        await Future<void>.delayed(const Duration(milliseconds: 5));
        socket.destroy();
      }
      final latest = request(range: 'bytes=50-59');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      gate.complete();
      final response = await latest;
      expect(response.statusCode, 206);
      expect(await response.expand((chunk) => chunk).toList(), List.filled(10, 0));
    } finally {
      if (!gate.isCompleted) gate.complete();
      for (final socket in sockets) {
        socket.destroy();
      }
    }
  });

  test('empty files have a valid HEAD and GET, but no satisfiable range', () async {
    await proxy.close();
    reader = MemorySmbReader(Uint8List(0));
    proxy = await SmbHttpPlaybackProxy.start(reader);
    final response = await request();
    expect(response.statusCode, 200);
    expect(response.contentLength, 0);
    await response.drain<void>();
    final partial = await request(range: 'bytes=0-');
    expect(partial.statusCode, 416);
    await partial.drain<void>();
  });

  test('streams bounded chunks and tolerates short SMB reads', () async {
    await proxy.close();
    reader = MemorySmbReader(Uint8List.fromList(List.generate(600000, (i) => i % 251)), maxRead: 65536);
    proxy = await SmbHttpPlaybackProxy.start(reader);
    final response = await request(range: 'bytes=10-599999');
    expect(await response.expand((chunk) => chunk).toList(), reader.bytes.sublist(10));
    expect(reader.reads.every((read) => read.$2 <= 256 * 1024), isTrue);
  });

  test('source read failures produce a generic gateway error', () async {
    await proxy.close();
    reader = MemorySmbReader(Uint8List(10), beforeRead: () async => throw StateError('secret NAS path'));
    proxy = await SmbHttpPlaybackProxy.start(reader);
    final response = await request();
    expect(response.statusCode, 502);
    expect(await response.expand((chunk) => chunk).toList(), isEmpty);
  });

  test('closing during a read closes the listener and reader exactly once', () async {
    await proxy.close();
    final started = Completer<void>();
    final gate = Completer<void>();
    reader = MemorySmbReader(
      Uint8List(10),
      beforeRead: () {
        started.complete();
        return gate.future;
      },
      onClose: () => gate.complete(),
    );
    proxy = await SmbHttpPlaybackProxy.start(reader);
    final oldUri = proxy.uri;
    final pending = request();
    final failed = expectLater(pending, throwsA(isA<HttpException>()));
    await started.future;
    await Future.wait([proxy.close(), proxy.close()]);
    await failed;
    expect(reader.closeCalls, 1);
    expect(await request(uri: oldUri).then((_) => false, onError: (Object _) => true), isTrue);
  });
}
