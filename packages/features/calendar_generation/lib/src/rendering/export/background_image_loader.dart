import 'dart:convert';
import 'dart:io';

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

      final parsedUri = Uri.tryParse(normalizedUrl);
      if (parsedUri != null && parsedUri.scheme == 'file') {
        final file = File.fromUri(parsedUri);
        if (!await file.exists()) {
          return null;
        }
        return file.readAsBytes();
      }

      if (_looksLikeAbsoluteLocalPath(normalizedUrl)) {
        final file = File(normalizedUrl);
        if (!await file.exists()) {
          return null;
        }
        return file.readAsBytes();
      }

      final uri = Uri.parse(normalizedUrl);
      final data = await NetworkAssetBundle(uri).load(uri.toString());
      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  bool _isDataImageUri(String value) {
    return value.startsWith('data:image/') && value.contains(';base64,');
  }

  bool _looksLikeAbsoluteLocalPath(String value) {
    if (value.startsWith('/')) {
      return true;
    }
    return RegExp(r'^[a-zA-Z]:[\\\/]').hasMatch(value);
  }
}
