import 'dart:convert';

import 'package:calendar_studio/calendar_studio.dart';
import 'package:shared_preferences/shared_preferences.dart';

CalendarStudioAssetStore createCalendarStudioAssetStore(
  SharedPreferences preferences,
) => _PreferencesStudioAssetStore(preferences);

class _PreferencesStudioAssetStore implements CalendarStudioAssetStore {
  _PreferencesStudioAssetStore(this._preferences);
  static const _key = 'calendar_studio.assets.web.v1';
  final SharedPreferences _preferences;
  Map<String, dynamic> _read() {
    final raw = _preferences.getString(_key);
    return raw == null ? {} : Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> _write(Map<String, dynamic> value) =>
      _preferences.setString(_key, jsonEncode(value));
  @override
  Future<CalendarStudioAsset> importAsset(
    CalendarStudioAssetInput input,
  ) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final values = _read();
    values[id] = {
      'name': input.name,
      'bytes': base64Encode(input.bytes),
      'width': input.width,
      'height': input.height,
    };
    await _write(values);
    return CalendarStudioAsset(
      id: id,
      name: input.name,
      width: input.width,
      height: input.height,
    );
  }

  @override
  Future<CalendarStudioAsset?> load(String assetId) async {
    final value = _read()[assetId];
    if (value is! Map) return null;
    return CalendarStudioAsset(
      id: assetId,
      name: value['name'] as String,
      width: value['width'] as int? ?? 0,
      height: value['height'] as int? ?? 0,
    );
  }

  @override
  Future<List<int>?> loadBytes(String assetId) async {
    final value = _read()[assetId];
    return value is Map ? base64Decode(value['bytes'] as String) : null;
  }

  @override
  Future<void> deleteUnusedAssets(Set<String> usedAssetIds) async {
    final values = _read()..removeWhere((id, _) => !usedAssetIds.contains(id));
    await _write(values);
  }
}
