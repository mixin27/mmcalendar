import 'dart:convert';

import 'package:flutter/services.dart';

class BackgroundImageLoader {
  Future<Uint8List?> loadBytes(String? url) async {
    final normalizedUrl = url?.trim();
    if (normalizedUrl == null || normalizedUrl.isEmpty) {
      return null;
    }

    try {
      if (_isDataImageUri(normalizedUrl)) {
        final payloadStart = normalizedUrl.indexOf('base64,');
        if (payloadStart < 0) {
          return null;
        }
        final encoded = normalizedUrl.substring(payloadStart + 7);
        return base64Decode(encoded);
      }

      final uri = Uri.parse(normalizedUrl);
      final data = await NetworkAssetBundle(uri).load(normalizedUrl);
      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  bool _isDataImageUri(String value) {
    return value.startsWith('data:image/') && value.contains(';base64,');
  }
}
