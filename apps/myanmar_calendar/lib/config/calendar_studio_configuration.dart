import 'dart:convert';
import 'dart:typed_data';

import 'package:calendar_studio/calendar_studio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:integrations_database/integrations_database.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'di_setup.dart';
import 'calendar_studio_asset_store.dart';
import 'calendar_studio_image_picker.dart';

/// App integration kept deliberately small until the Studio Drift migration.
/// The package remains reusable; this adapter is the only app-specific seam.
final CalendarStudioConfiguration calendarStudioConfiguration =
    CalendarStudioConfiguration(
      projects: _StudioProjectStore(
        CalendarStudioProjectDatabase(getIt<AppDatabase>()),
        getIt<SharedPreferences>(),
      ),
      calendarData: const MyanmarCalendarStudioDataProvider(),
      assets: createCalendarStudioAssetStore(getIt<SharedPreferences>()),
      exportDelivery: const _StudioExportDelivery(),
      imagePicker: AppCalendarStudioImagePicker(),
    );

class _StudioProjectStore implements CalendarStudioProjectStore {
  _StudioProjectStore(this._database, this._preferences);

  static const _legacyKey = 'calendar_studio.projects.v1';
  static const _migrationKey = 'calendar_studio.projects.drift-migrated.v1';
  final CalendarStudioProjectDatabase _database;
  final SharedPreferences _preferences;
  Future<void>? _migration;

  Future<void> _ensureMigrated() => _migration ??= _migrateLegacyProjects();

  Future<void> _migrateLegacyProjects() async {
    if (_preferences.getBool(_migrationKey) ?? false) return;
    final raw = _preferences.getString(_legacyKey);
    if (raw == null || raw.isEmpty) {
      await _preferences.setBool(_migrationKey, true);
      return;
    }
    late final List<dynamic> decoded;
    try {
      decoded = jsonDecode(raw) as List;
    } catch (_) {
      return;
    }
    var everyDocumentWasValid = true;
    for (final item in decoded) {
      late final CalendarStudioProject project;
      try {
        project = CalendarStudioDocumentCodec.decode(
          Map<String, dynamic>.from(item as Map),
        );
      } catch (_) {
        everyDocumentWasValid = false;
        continue;
      }
      await _saveToDatabase(project);
    }
    if (everyDocumentWasValid) {
      // Keep the legacy JSON as a non-destructive recovery copy.
      await _preferences.setBool(_migrationKey, true);
    }
  }

  CalendarStudioProject _decode(String documentJson) =>
      CalendarStudioDocumentCodec.decode(
        Map<String, dynamic>.from(jsonDecode(documentJson) as Map),
      );

  Future<void> _saveToDatabase(CalendarStudioProject project) => _database.save(
    id: project.id,
    name: project.name,
    templateId: project.templateId,
    documentSchemaVersion: project.schemaVersion,
    documentJson: jsonEncode(CalendarStudioDocumentCodec.encode(project)),
    createdAt: project.createdAt,
    updatedAt: project.updatedAt,
  );

  @override
  Future<void> delete(String id) async {
    await _ensureMigrated();
    await _database.delete(id);
  }

  @override
  Future<List<CalendarStudioProject>> list() async {
    await _ensureMigrated();
    return (await _database.list())
        .map((row) => _decode(row.documentJson))
        .toList(growable: false);
  }

  @override
  Future<CalendarStudioProject?> load(String id) async {
    await _ensureMigrated();
    final row = await _database.load(id);
    return row == null ? null : _decode(row.documentJson);
  }

  @override
  Future<void> save(CalendarStudioProject project) async {
    await _ensureMigrated();
    await _saveToDatabase(project);
  }
}

class _StudioExportDelivery implements CalendarStudioExportDelivery {
  const _StudioExportDelivery();

  @override
  Future<void> deliver(
    CalendarStudioExportArtifact artifact, {
    CalendarStudioExportDestination destination =
        CalendarStudioExportDestination.save,
  }) async {
    final bytes = Uint8List.fromList(artifact.bytes);
    switch (destination) {
      case CalendarStudioExportDestination.save:
        await FilePicker.platform.saveFile(
          dialogTitle: 'Save calendar export',
          fileName: artifact.name,
          bytes: bytes,
        );
      case CalendarStudioExportDestination.share:
        await SharePlus.instance.share(
          ShareParams(
            title: 'Calendar Studio export',
            subject: artifact.name,
            files: [
              XFile.fromData(
                bytes,
                mimeType: artifact.mimeType,
                name: artifact.name,
              ),
            ],
            fileNameOverrides: [artifact.name],
          ),
        );
      case CalendarStudioExportDestination.print:
        if (artifact.mimeType != 'application/pdf') {
          throw ArgumentError('Only PDF calendar exports can be printed.');
        }
        await Printing.layoutPdf(
          name: artifact.name,
          onLayout: (_) async => bytes,
        );
    }
  }
}
