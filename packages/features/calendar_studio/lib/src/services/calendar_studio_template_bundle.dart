import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../models/calendar_studio_user_template.dart';
import 'calendar_studio_contracts.dart';
import 'calendar_studio_document_codec.dart';
import 'calendar_studio_project_bundle.dart';
import 'calendar_studio_zip.dart';

/// Why a template file could not be read; [message] is shown to the user.
class CalendarStudioTemplateFileException
    extends CalendarStudioProjectFileException {
  const CalendarStudioTemplateFileException(super.message);
}

/// A template file read into memory but not yet saved, so the user can
/// review it before importing.
class CalendarStudioTemplateFile {
  const CalendarStudioTemplateFile({
    required this.template,
    required this.assets,
    required this.missingAssetIds,
    required this.sizeInBytes,
  });
  final CalendarStudioUserTemplate template;

  /// Images in the file, by their id in [template].
  final Map<String, CalendarStudioProjectFileAsset> assets;

  /// Images the design refers to that the file does not contain.
  final Set<String> missingAssetIds;
  final int sizeInBytes;
}

/// Stores the user's templates; the host decides where (the app uses Drift).
abstract interface class CalendarStudioTemplateStore {
  /// Most recently changed first.
  Future<List<CalendarStudioUserTemplate>> list();

  /// Adds or replaces the template with the same id.
  Future<void> save(CalendarStudioUserTemplate template);
  Future<void> delete(String id);
}

/// Portable `.mmctemplate` files: a zip holding `manifest.json`,
/// `template.json`, `preview.png` and `assets/<id>.<ext>` for each image
/// the design keeps. The schema is in
/// `docs/architecture/calendar_studio_template_format.md`.
abstract final class CalendarStudioTemplateBundle {
  static const format = 'mmcalendar.studio.template';
  static const version = 1;
  static const extension = 'mmctemplate';
  static const mimeType = 'application/zip';

  /// Hard limit for files read from disk or other apps.
  static const maxBytes = 50 << 20;

  /// `template.json`. The preview travels as its own file.
  static Map<String, Object?> encode(CalendarStudioUserTemplate template) => {
    'formatVersion': CalendarStudioUserTemplate.formatVersion,
    'id': template.id,
    'name': template.name,
    'author': ?template.author,
    'description': ?template.description,
    'basePresetId': template.basePresetId,
    'category': template.category,
    'monthly': template.monthly,
    'moods': template.moods,
    'palette': template.palette,
    'canvas': CalendarStudioDocumentCodec.encodeCanvas(template.canvas),
    'blocks': template.blocks
        .map(CalendarStudioDocumentCodec.encodeBlock)
        .toList(),
    'createdAt': template.createdAt.toUtc().toIso8601String(),
    'updatedAt': template.updatedAt.toUtc().toIso8601String(),
  };

  /// Reads `template.json`; throws [FormatException] for anything invalid
  /// and [CalendarStudioTemplateFileException] for a newer format.
  static CalendarStudioUserTemplate decode(
    Map<String, dynamic> value, {
    Uint8List? preview,
  }) {
    final formatVersion = value['formatVersion'];
    if (formatVersion is! int) throw const FormatException('formatVersion');
    if (formatVersion > CalendarStudioUserTemplate.formatVersion) {
      throw _newer;
    }
    final name = value['name'];
    final id = value['id'];
    if (name is! String || name.trim().isEmpty || id is! String) {
      throw const FormatException('name');
    }
    return CalendarStudioUserTemplate(
      id: id,
      name: name,
      author: value['author'] as String?,
      description: value['description'] as String?,
      basePresetId: value['basePresetId'] as String? ?? 'blank',
      category: value['category'] as String? ?? 'Custom',
      monthly: value['monthly'] as bool? ?? true,
      moods: [
        for (final mood in value['moods'] as List? ?? const [])
          if (mood is String) mood,
      ],
      palette: [
        for (final color in value['palette'] as List? ?? const [])
          if (color is int) color,
      ],
      canvas: CalendarStudioDocumentCodec.decodeCanvas(
        Map<String, dynamic>.from(value['canvas'] as Map),
      ),
      blocks: [
        for (final block in value['blocks'] as List)
          CalendarStudioDocumentCodec.decodeBlock(
            Map<String, dynamic>.from(block as Map),
          ),
      ],
      createdAt: DateTime.parse(value['createdAt'] as String),
      updatedAt: DateTime.parse(
        value['updatedAt'] as String? ?? value['createdAt'] as String,
      ),
      preview: preview,
    );
  }

  static Future<CalendarStudioExportArtifact> export(
    CalendarStudioUserTemplate template, {
    CalendarStudioAssetStore? assets,
    required String fileName,
    DateTime? now,
  }) async {
    final entries = <Map<String, Object?>>[];
    final files = <String, Uint8List>{};
    for (final id in template.assetIds) {
      final raw = await assets?.loadBytes(id);
      if (raw == null || raw.isEmpty) continue;
      final asset = await assets?.load(id);
      final name = asset?.name ?? id;
      final path =
          'assets/${CalendarStudioZip.safeSegment(id)}'
          '${CalendarStudioZip.extensionOf(name)}';
      files[path] = raw is Uint8List ? raw : Uint8List.fromList(raw);
      entries.add({
        'id': id,
        'file': path,
        'name': name,
        'width': asset?.width ?? 0,
        'height': asset?.height ?? 0,
      });
    }
    final preview = template.preview;
    final manifest = {
      'format': format,
      'version': version,
      'createdAt': (now ?? DateTime.now()).toUtc().toIso8601String(),
      'name': template.name,
      'author': ?template.author,
      'canvas': {
        'width': template.canvas.width,
        'height': template.canvas.height,
      },
      'monthly': template.monthly,
      if (preview != null) 'preview': 'preview.png',
      'assets': entries,
    };
    final bytes = await CalendarStudioZip.encode({
      'manifest.json': utf8.encode(jsonEncode(manifest)),
      'template.json': utf8.encode(jsonEncode(encode(template))),
      'preview.png': ?preview,
      ...files,
    });
    return CalendarStudioExportArtifact(
      name: '$fileName.$extension',
      mimeType: mimeType,
      bytes: bytes,
    );
  }

  static Future<CalendarStudioTemplateFile> read(Uint8List bytes) async {
    if (bytes.length > maxBytes) {
      throw const CalendarStudioTemplateFileException(
        'This file is larger than 50 MB, so it can\'t be imported.',
      );
    }
    final Map<String, Uint8List> files;
    try {
      files = await CalendarStudioZip.decode(
        bytes,
        names: const {'manifest.json', 'template.json', 'preview.png'},
        maxBytes: maxBytes,
      );
    } catch (_) {
      throw _notTemplate;
    }
    final manifestBytes = files['manifest.json'];
    final templateBytes = files['template.json'];
    if (manifestBytes == null || templateBytes == null) throw _notTemplate;
    final Map<String, dynamic> manifest;
    final CalendarStudioUserTemplate template;
    try {
      manifest = Map<String, dynamic>.from(
        jsonDecode(utf8.decode(manifestBytes)) as Map,
      );
      if (manifest['format'] != format) throw _notTemplate;
      final fileVersion = manifest['version'];
      if (fileVersion is! int) throw const FormatException();
      if (fileVersion > version) throw _newer;
      template = decode(
        Map<String, dynamic>.from(
          jsonDecode(utf8.decode(templateBytes)) as Map,
        ),
        preview: files['preview.png'],
      );
    } on CalendarStudioTemplateFileException {
      rethrow;
    } catch (_) {
      throw const CalendarStudioTemplateFileException(
        'This template file is damaged and can\'t be opened.',
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
    return CalendarStudioTemplateFile(
      template: template,
      assets: assets,
      missingAssetIds: template.assetIds.difference(assets.keys.toSet()),
      sizeInBytes: bytes.length,
    );
  }

  /// Saves [file] as a new template: a new id, and images copied into
  /// [assets] under new ids. Images the file lacks leave empty photo slots.
  static Future<CalendarStudioUserTemplate> import(
    CalendarStudioTemplateFile file, {
    required CalendarStudioTemplateStore templates,
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
    final template = file.template.copyWith(
      id: CalendarStudioZip.uuid(),
      createdAt: time,
      updatedAt: time,
      blocks: [
        for (final block in file.template.blocks)
          block.copyWith(content: remapAssets(block.content, remapped)),
      ],
    );
    await templates.save(template);
    return template;
  }

  /// Points asset keys at [remapped] ids; references to images not in
  /// [remapped] are dropped.
  static Map<String, Object?> remapAssets(
    Map<String, Object?> content,
    Map<String, String> remapped,
  ) {
    const keys = CalendarStudioUserTemplate.assetKeys;
    if (!keys.any(content.containsKey)) return content;
    return {
      for (final entry in content.entries)
        if (!keys.contains(entry.key))
          entry.key: entry.value
        else if (remapped[entry.value] case final String id)
          entry.key: id,
    };
  }

  /// Lets the user pick a template file. Mobile pickers can't filter by an
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

  static const _notTemplate = CalendarStudioTemplateFileException(
    "This isn't a Calendar Studio template file.",
  );
  static const _newer = CalendarStudioTemplateFileException(
    'This template was made with a newer version of the app. '
    'Update the app, then import it again.',
  );
}
