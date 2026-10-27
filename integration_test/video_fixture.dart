// 【冒烟素材】在临时目录生成原生播放冒烟所需的视频。
// 不下载素材，不写入用户媒体库。

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// 在测试应用沙箱内生成动态 RGB AVI，不依赖网络、外部编码器、受版权保护的素材或仓库二进制资产。
Future<File> createVideoFixture(Directory directory, {int frames = 100}) async {
  const width = 160, height = 90, fps = 10;
  const frameSize = width * height * 3;
  Uint8List words(List<int> values) {
    final data = ByteData(values.length * 4);
    for (var i = 0; i < values.length; i++) {
      data.setUint32(i * 4, values[i], Endian.little);
    }
    return data.buffer.asUint8List();
  }

  Uint8List join(List<List<int>> parts) {
    final result = BytesBuilder(copy: false);
    for (final part in parts) {
      result.add(part);
    }
    return result.takeBytes();
  }

  Uint8List chunk(String tag, List<int> bytes) => join([
    ascii.encode(tag),
    words([bytes.length]),
    bytes,
    if (bytes.length.isOdd) [0],
  ]);
  Uint8List group(String tag, List<int> bytes) => chunk('LIST', join([ascii.encode(tag), bytes]));
  final streamHeader = ByteData(56);
  streamHeader.buffer.asUint8List().setRange(0, 8, ascii.encode('vidsDIB '));
  for (final field in {20: 1, 24: fps, 32: frames, 36: frameSize, 40: 0xffffffff}.entries) {
    streamHeader.setUint32(field.key, field.value, Endian.little);
  }
  streamHeader.setInt16(52, width, Endian.little);
  streamHeader.setInt16(54, height, Endian.little);
  final format = ByteData(40);
  for (final field in {0: 40, 4: width, 8: height, 20: frameSize}.entries) {
    format.setUint32(field.key, field.value, Endian.little);
  }
  format.setUint16(12, 1, Endian.little);
  format.setUint16(14, 24, Endian.little);
  final header = group(
    'hdrl',
    join([
      chunk(
        'avih',
        words([1000000 ~/ fps, frameSize * fps, 0, 16, frames, 0, 1, frameSize, width, height, 0, 0, 0, 0]),
      ),
      group(
        'strl',
        join([chunk('strh', streamHeader.buffer.asUint8List()), chunk('strf', format.buffer.asUint8List())]),
      ),
    ]),
  );
  final video = BytesBuilder(copy: false), index = BytesBuilder(copy: false);
  var offset = 4;
  for (var frame = 0; frame < frames; frame++) {
    final pixels = Uint8List(frameSize);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final bright = (x - frame * 3) % width < 20, start = (y * width + x) * 3;
        pixels[start] = bright ? 30 : x;
        pixels[start + 1] = bright ? 240 : y * 2;
        pixels[start + 2] = bright ? 250 : 50;
      }
    }
    final block = chunk('00db', pixels);
    video.add(block);
    index.add(
      join([
        ascii.encode('00db'),
        words([16, offset, frameSize]),
      ]),
    );
    offset += block.length;
  }
  final payload = join([
    ascii.encode('AVI '),
    header,
    group('movi', video.takeBytes()),
    chunk('idx1', index.takeBytes()),
  ]);
  return File('${directory.path}/fixture.avi').writeAsBytes(
    join([
      ascii.encode('RIFF'),
      words([payload.length]),
      payload,
    ]),
  );
}
