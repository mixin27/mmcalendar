import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

final _fonts = <String, Future<Uint8List?>>{};

/// Fetches a generated export font from this site (`/export-fonts/`); the
/// browser's cache keeps it after the first export.
Future<Uint8List?> downloadCalendarStudioExportFont(String fileName) =>
    _fonts.putIfAbsent(fileName, () async {
      try {
        final response = await web.window
            .fetch(Uri.base.resolve('/export-fonts/$fileName').toString().toJS)
            .toDart;
        if (!response.ok) return null;
        final buffer = await response.arrayBuffer().toDart;
        return buffer.toDart.asUint8List();
      } catch (_) {
        return null;
      }
    });
