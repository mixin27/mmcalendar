import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

/// [picture] as a 24-bit PNG with no alpha channel: Google Play rejects
/// a feature graphic with one, and the App Store rejects screenshots with
/// transparency.
Future<List<int>> encodeRgbPng(ui.Picture picture, ui.Size size) async {
  final width = size.width.round(), height = size.height.round();
  final image = await picture.toImage(width, height);
  final rgba = (await image.toByteData(
    format: ui.ImageByteFormat.rawRgba,
  ))!.buffer.asUint8List();
  // Each row: filter type 0, then RGB.
  final raw = Uint8List(height * (1 + width * 3));
  var o = 0;
  for (var y = 0; y < height; y++) {
    raw[o++] = 0;
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      raw[o++] = rgba[i];
      raw[o++] = rgba[i + 1];
      raw[o++] = rgba[i + 2];
    }
  }
  final header = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8) // bit depth
    ..setUint8(9, 2); // colour type: RGB
  return [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // signature
    ..._chunk('IHDR', header.buffer.asUint8List()),
    ..._chunk('IDAT', ZLibCodec(level: 6).encode(raw)),
    ..._chunk('IEND', const []),
  ];
}

List<int> _chunk(String type, List<int> data) {
  final body = [...type.codeUnits, ...data];
  final out = ByteData(8 + data.length + 4);
  out.setUint32(0, data.length);
  final bytes = out.buffer.asUint8List()..setRange(4, 8 + data.length, body);
  out.setUint32(8 + data.length, _crc32(body));
  return bytes;
}

final _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >>> 1) : c >>> 1;
  }
  return c;
});

int _crc32(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final b in bytes) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >>> 8);
  }
  return c ^ 0xFFFFFFFF;
}
