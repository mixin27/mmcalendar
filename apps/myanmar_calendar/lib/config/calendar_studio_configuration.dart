import 'dart:convert';
import 'dart:typed_data';

import 'package:calendar_studio/calendar_studio.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'di_setup.dart';

/// App integration kept deliberately small until the Studio Drift migration.
/// The package remains reusable; this adapter is the only app-specific seam.
final CalendarStudioConfiguration calendarStudioConfiguration =
    CalendarStudioConfiguration(
      projects: _StudioProjectStore(getIt<SharedPreferences>()),
      calendarData: const MyanmarCalendarStudioDataProvider(),
      exportDelivery: const _StudioExportDelivery(),
    );

class _StudioProjectStore implements CalendarStudioProjectStore {
  _StudioProjectStore(this._preferences);

  static const _key = 'calendar_studio.projects.v1';
  final SharedPreferences _preferences;

  Future<Map<String, CalendarStudioProject>> _read() async {
    final raw = _preferences.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw) as List;
    return {
      for (final item in decoded)
        (item as Map<String, dynamic>)['id'] as String:
            CalendarStudioDocumentCodec.decode(item),
    };
  }

  Future<void> _write(Map<String, CalendarStudioProject> projects) =>
      _preferences.setString(
        _key,
        jsonEncode(
          projects.values.map(CalendarStudioDocumentCodec.encode).toList(),
        ),
      );

  @override
  Future<void> delete(String id) async {
    final projects = await _read();
    projects.remove(id);
    await _write(projects);
  }

  @override
  Future<List<CalendarStudioProject>> list() async {
    final values = (await _read()).values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return values;
  }

  @override
  Future<CalendarStudioProject?> load(String id) async => (await _read())[id];

  @override
  Future<void> save(CalendarStudioProject project) async {
    final projects = await _read();
    projects[project.id] = project;
    await _write(projects);
  }
}

class _StudioExportDelivery implements CalendarStudioExportDelivery {
  const _StudioExportDelivery();

  @override
  Future<void> deliver(CalendarStudioExportArtifact artifact) {
    return Printing.sharePdf(
      bytes: Uint8List.fromList(artifact.bytes),
      filename: artifact.name,
    );
  }
}
