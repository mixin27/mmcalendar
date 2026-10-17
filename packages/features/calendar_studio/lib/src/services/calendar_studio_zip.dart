import 'dart:math';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';

/// Zip helpers shared by `.mmcstudio` projects and `.mmctemplate` templates.
abstract final class CalendarStudioZip {
  static Future<Uint8List> encode(Map<String, List<int>> files) =>
      compute(_encode, files);

  /// Reads only plain entries named in [names] or under `assets/`: no
  /// directories, no absolute or parent paths, and the total stays under
  /// [maxBytes]. Throws when [bytes] is not a zip or is too large.
  static Future<Map<String, Uint8List>> decode(
    Uint8List bytes, {
    required Set<String> names,
    required int maxBytes,
  }) => compute(_decode, (bytes, names, maxBytes));

  /// A file-name-safe version of an id.
  static String safeSegment(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');

  /// ".png" from "photo.PNG"; empty when there is none.
  static String extensionOf(String name) {
    final match = RegExp(r'\.[A-Za-z0-9]{1,5}$').firstMatch(name);
    return match?.group(0)?.toLowerCase() ?? '';
  }

  /// A random (version 4) UUID.
  static String uuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}

Uint8List _encode(Map<String, List<int>> files) {
  final archive = Archive();
  for (final MapEntry(key: path, value: data) in files.entries) {
    archive.addFile(ArchiveFile(path, data.length, data));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

Map<String, Uint8List> _decode((Uint8List, Set<String>, int) message) {
  final (bytes, names, maxBytes) = message;
  final archive = ZipDecoder().decodeBytes(bytes);
  final files = <String, Uint8List>{};
  var total = 0;
  for (final file in archive.files) {
    if (!file.isFile) continue;
    final name = file.name;
    final allowed =
        names.contains(name) ||
        RegExp(r'^assets/[A-Za-z0-9._-]+$').hasMatch(name);
    if (!allowed || name.contains('..')) continue;
    final data = file.content;
    total += data.length;
    if (total > maxBytes) throw StateError('Archive too large');
    files[name] = data;
  }
  return files;
}
