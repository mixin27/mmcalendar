import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../models/calendar_studio_document.dart';
import 'calendar_studio_contracts.dart';
import 'calendar_studio_document_codec.dart';

/// Why a project file could not be read; [message] is shown to the user.
class CalendarStudioProjectFileException implements Exception {
  const CalendarStudioProjectFileException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// A project file read into memory but not yet saved, so the user can review
/// it before importing.
class CalendarStudioProjectFile {
  const CalendarStudioProjectFile({
    required this.project,
    required this.assets,
    required this.missingAssetIds,
    required this.sizeInBytes,
  });
  final CalendarStudioProject project;

  /// Images in the file, by their id in [project].
  final Map<String, CalendarStudioProjectFileAsset> assets;

  /// Images the project refers to that the file does not contain.
  final Set<String> missingAssetIds;
  final int sizeInBytes;
}

class CalendarStudioProjectFileAsset {
  const CalendarStudioProjectFileAsset({
    required this.name,
    required this.bytes,
    required this.width,
    required this.height,
  });
  final String name;
  final Uint8List bytes;
  final int width;
  final int height;
}

/// Portable `.mmcstudio` project files: a zip holding `manifest.json`,
/// `project.json` (the document codec) and `assets/<id>.<ext>` for every
/// image the project uses. Importing always creates a new project with new
/// ids, so nothing on the device is overwritten.
abstract final class CalendarStudioProjectBundle {
  static const format = 'mmcalendar.studio.project';
  static const version = 1;
  static const extension = 'mmcstudio';
  static const mimeType = 'application/zip';

  /// Hard limit for files read from disk or other apps.
  static const maxBytes = 200 << 20;

  /// Block content keys that hold asset ids.
  static const assetKeys = ['assetId', 'originalAssetId', 'editBaseAssetId'];

  static Set<String> referencedAssetIds(CalendarStudioProject project) => {
    for (final page in project.pages)
      for (final block in page.blocks)
        for (final key in assetKeys)
          if (block.content[key] case final String id) id,
  };

  static Future<CalendarStudioExportArtifact> export(
    CalendarStudioProject project, {
    CalendarStudioAssetStore? assets,
    required String fileName,
    DateTime? now,
  }) async {
    final entries = <Map<String, Object?>>[];
    final files = <String, Uint8List>{};
    for (final id in referencedAssetIds(project)) {
      final raw = await assets?.loadBytes(id);
      if (raw == null || raw.isEmpty) continue;
      final asset = await assets?.load(id);
      final name = asset?.name ?? id;
      final path = 'assets/${_safeSegment(id)}${_extensionOf(name)}';
      files[path] = raw is Uint8List ? raw : Uint8List.fromList(raw);
      entries.add({
        'id': id,
        'file': path,
        'name': name,
        'width': asset?.width ?? 0,
        'height': asset?.height ?? 0,
      });
    }
    final manifest = {
      'format': format,
      'version': version,
      'schemaVersion': project.schemaVersion,
      'createdAt': (now ?? DateTime.now()).toUtc().toIso8601String(),
      'name': project.name,
      'pages': project.pages.length,
      'assets': entries,
    };
    final bytes = await compute(_encodeZip, {
      'manifest.json': utf8.encode(jsonEncode(manifest)),
      'project.json': utf8.encode(
        jsonEncode(CalendarStudioDocumentCodec.encode(project)),
      ),
      ...files,
    });
    return CalendarStudioExportArtifact(
      name: '$fileName.$extension',
      mimeType: mimeType,
      bytes: bytes,
    );
  }

  static Future<CalendarStudioProjectFile> read(Uint8List bytes) async {
    if (bytes.length > maxBytes) {
      throw const CalendarStudioProjectFileException(
        'This file is larger than 200 MB, so it can\'t be imported.',
      );
    }
    final Map<String, Uint8List> files;
    try {
      files = await compute(_decodeZip, bytes);
    } catch (_) {
      throw const CalendarStudioProjectFileException(
        "This isn't a Calendar Studio project file.",
      );
    }
    final manifestBytes = files['manifest.json'];
    final projectBytes = files['project.json'];
    if (manifestBytes == null || projectBytes == null) {
      throw const CalendarStudioProjectFileException(
        "This isn't a Calendar Studio project file.",
      );
    }
    final Map<String, dynamic> manifest;
    final CalendarStudioProject project;
    try {
      manifest = Map<String, dynamic>.from(
        jsonDecode(utf8.decode(manifestBytes)) as Map,
      );
      if (manifest['format'] != format) throw const FormatException();
      final fileVersion = manifest['version'];
      if (fileVersion is! int) throw const FormatException();
      if (fileVersion > version) {
        throw const CalendarStudioProjectFileException(
          'This project was made with a newer version of the app. '
          'Update the app, then import it again.',
        );
      }
      project = CalendarStudioDocumentCodec.decode(
        Map<String, dynamic>.from(jsonDecode(utf8.decode(projectBytes)) as Map),
      );
    } on CalendarStudioProjectFileException {
      rethrow;
    } catch (_) {
      throw const CalendarStudioProjectFileException(
        'This project file is damaged and can\'t be opened.',
      );
    }
    final assets = <String, CalendarStudioProjectFileAsset>{};
    for (final entry in (manifest['assets'] as List? ?? const [])) {
      if (entry is! Map) continue;
      final id = entry['id'];
      final file = entry['file'];
      if (id is! String || file is! String) continue;
      final data = files[file];
      if (data == null) continue;
      assets[id] = CalendarStudioProjectFileAsset(
        name: entry['name'] as String? ?? id,
        bytes: data,
        width: entry['width'] as int? ?? 0,
        height: entry['height'] as int? ?? 0,
      );
    }
    return CalendarStudioProjectFile(
      project: project,
      assets: assets,
      missingAssetIds: referencedAssetIds(
        project,
      ).difference(assets.keys.toSet()),
      sizeInBytes: bytes.length,
    );
  }

  /// Saves [file] as a new project: new project and page ids, images copied
  /// into [assets] under new ids, and the name marked "(imported)".
  static Future<CalendarStudioProject> import(
    CalendarStudioProjectFile file, {
    required CalendarStudioProjectStore projects,
    CalendarStudioAssetStore? assets,
    DateTime? now,
  }) async {
    final time = now ?? DateTime.now();
    final remapped = <String, String>{};
    if (assets != null) {
      for (final MapEntry(key: oldId, value: asset) in file.assets.entries) {
        final stored = await assets.importAsset(
          CalendarStudioAssetInput(
            name: asset.name,
            bytes: asset.bytes,
            width: asset.width,
            height: asset.height,
          ),
        );
        remapped[oldId] = stored.id;
      }
    }
    final source = file.project;
    final stamp = time.microsecondsSinceEpoch;
    final project = CalendarStudioProject(
      id: '$stamp',
      name: '${source.name} (imported)',
      templateId: source.templateId,
      source: source.source,
      createdAt: time,
      updatedAt: time,
      defaultExportPreset: source.defaultExportPreset,
      pages: [
        for (final page in source.pages)
          page.copyWith(
            blocks: [
              for (final block in page.blocks)
                block.copyWith(content: _remap(block.content, remapped)),
            ],
          ),
      ],
    );
    await projects.save(project);
    return project;
  }

  /// Points asset keys at the newly stored images; references to images the
  /// file did not include are dropped so preflight reports them.
  static Map<String, Object?> _remap(
    Map<String, Object?> content,
    Map<String, String> remapped,
  ) {
    if (!assetKeys.any(content.containsKey)) return content;
    return {
      for (final entry in content.entries)
        if (!assetKeys.contains(entry.key))
          entry.key: entry.value
        else if (remapped[entry.value] case final String id)
          entry.key: id,
    };
  }

  static String _safeSegment(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');

  static String _extensionOf(String name) {
    final match = RegExp(r'\.[A-Za-z0-9]{1,5}$').firstMatch(name);
    return match?.group(0)?.toLowerCase() ?? '';
  }

  /// Lets the user pick a project file. Mobile pickers can't filter by an
  /// unregistered extension, so they show all files and the content is
  /// validated on read.
  static Future<Uint8List?> pickFile() async {
    final mobile =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    final result = await FilePicker.platform.pickFiles(
      type: mobile ? FileType.any : FileType.custom,
      allowedExtensions: mobile ? null : const [extension, 'zip'],
      withData: true,
    );
    return result?.files.single.bytes;
  }
}

Uint8List _encodeZip(Map<String, List<int>> files) {
  final archive = Archive();
  for (final MapEntry(key: path, value: data) in files.entries) {
    archive.addFile(ArchiveFile(path, data.length, data));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

/// Only plain entries we know how to use are read: no directories, no
/// absolute or parent paths, and the total stays under the size limit.
Map<String, Uint8List> _decodeZip(Uint8List bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  final files = <String, Uint8List>{};
  var total = 0;
  for (final file in archive.files) {
    if (!file.isFile) continue;
    final name = file.name;
    final allowed =
        name == 'manifest.json' ||
        name == 'project.json' ||
        RegExp(r'^assets/[A-Za-z0-9._-]+$').hasMatch(name);
    if (!allowed || name.contains('..')) continue;
    final data = file.content;
    total += data.length;
    if (total > CalendarStudioProjectBundle.maxBytes) {
      throw StateError('Archive too large');
    }
    files[name] = data;
  }
  return files;
}
