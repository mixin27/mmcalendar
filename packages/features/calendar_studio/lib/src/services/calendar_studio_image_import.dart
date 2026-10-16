import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'calendar_studio_contracts.dart';

class CalendarStudioPreparedImage {
  const CalendarStudioPreparedImage({
    required this.name,
    required this.bytes,
    required this.width,
    required this.height,
    required this.resized,
  });
  final String name;
  final Uint8List bytes;
  final int width;
  final int height;

  /// Whether the original was larger than the import limit and was downsized.
  final bool resized;
}

class CalendarStudioUnsupportedImageException implements Exception {
  const CalendarStudioUnsupportedImageException(this.name);
  final String name;

  @override
  String toString() => 'Unsupported image: $name';
}

/// Normalises picked images before they are stored.
///
/// Dimensions come from the encoded header via [ui.ImageDescriptor], so
/// ordinary imports are never fully decoded on the UI isolate. Oversized
/// images are decoded at the target size by the engine and re-encoded on a
/// background isolate.
abstract final class CalendarStudioImageImport {
  /// Long edge kept on import: enough for a full A3 page at 300 dpi
  /// (4961 px) while keeping project storage and memory bounded.
  static const maxDimension = 5000;

  static Future<CalendarStudioPreparedImage> prepare(
    CalendarStudioPickedImage image, {
    int maxDimension = CalendarStudioImageImport.maxDimension,
  }) async {
    final ui.ImmutableBuffer buffer;
    final ui.ImageDescriptor descriptor;
    try {
      buffer = await ui.ImmutableBuffer.fromUint8List(image.bytes);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
    } catch (_) {
      throw CalendarStudioUnsupportedImageException(image.name);
    }
    try {
      final width = descriptor.width;
      final height = descriptor.height;
      final longEdge = math.max(width, height);
      if (longEdge <= maxDimension) {
        return CalendarStudioPreparedImage(
          name: image.name,
          bytes: image.bytes,
          width: width,
          height: height,
          resized: false,
        );
      }
      final scale = maxDimension / longEdge;
      final targetWidth = math.max(1, (width * scale).round());
      final targetHeight = math.max(1, (height * scale).round());
      final codec = await descriptor.instantiateCodec(
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
      final frame = await codec.getNextFrame();
      final rgba = await frame.image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      frame.image.dispose();
      codec.dispose();
      if (rgba == null) {
        throw CalendarStudioUnsupportedImageException(image.name);
      }
      final keepAlpha = _mayHaveAlpha(image.bytes);
      final encoded = await compute(
        _encode,
        _EncodeRequest(
          rgba.buffer.asUint8List(rgba.offsetInBytes, rgba.lengthInBytes),
          targetWidth,
          targetHeight,
          keepAlpha,
        ),
      );
      return CalendarStudioPreparedImage(
        name: _withExtension(image.name, keepAlpha ? 'png' : 'jpg'),
        bytes: encoded,
        width: targetWidth,
        height: targetHeight,
        resized: true,
      );
    } finally {
      descriptor.dispose();
      buffer.dispose();
    }
  }

  /// PNG, WebP and GIF can carry transparency (logos); keep it lossless.
  static bool _mayHaveAlpha(Uint8List bytes) {
    bool startsWith(List<int> signature, [int offset = 0]) {
      if (bytes.length < offset + signature.length) return false;
      for (var i = 0; i < signature.length; i++) {
        if (bytes[offset + i] != signature[i]) return false;
      }
      return true;
    }

    return startsWith(const [0x89, 0x50, 0x4E, 0x47]) || // PNG
        startsWith(const [0x47, 0x49, 0x46]) || // GIF
        (startsWith(const [0x52, 0x49, 0x46, 0x46]) && // RIFF....WEBP
            startsWith(const [0x57, 0x45, 0x42, 0x50], 8));
  }

  static String _withExtension(String name, String extension) {
    final dot = name.lastIndexOf('.');
    final base = dot > 0 ? name.substring(0, dot) : name;
    return '$base.$extension';
  }
}

class _EncodeRequest {
  const _EncodeRequest(this.rgba, this.width, this.height, this.keepAlpha);
  final Uint8List rgba;
  final int width;
  final int height;
  final bool keepAlpha;
}

Uint8List _encode(_EncodeRequest request) {
  final image = img.Image.fromBytes(
    width: request.width,
    height: request.height,
    bytes: request.rgba.buffer,
    bytesOffset: request.rgba.offsetInBytes,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );
  return request.keepAlpha
      ? img.encodePng(image, level: 6)
      : img.encodeJpg(image, quality: 92);
}

/// Default picker when the host supplies none: the system file chooser.
class CalendarStudioFileImagePicker implements CalendarStudioImagePicker {
  const CalendarStudioFileImagePicker();

  @override
  List<CalendarStudioImageSource> get sources => const [
    CalendarStudioImageSource.files,
  ];

  @override
  Future<CalendarStudioPickedImage?> pick(
    CalendarStudioImageSource source, {
    required int maxDimension,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.single;
    final bytes = file?.bytes;
    if (file == null || bytes == null) return null;
    return CalendarStudioPickedImage(name: file.name, bytes: bytes);
  }
}
