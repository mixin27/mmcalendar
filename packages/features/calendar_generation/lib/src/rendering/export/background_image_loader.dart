import 'package:flutter/services.dart';

class BackgroundImageLoader {
  Future<Uint8List?> loadBytes(String? url) async {
    final normalizedUrl = url?.trim();
    if (normalizedUrl == null || normalizedUrl.isEmpty) {
      return null;
    }

    try {
      final uri = Uri.parse(normalizedUrl);
      final data = await NetworkAssetBundle(uri).load(normalizedUrl);
      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }
}
