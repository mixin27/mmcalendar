import 'dart:convert';
import 'dart:typed_data';

import 'package:calendar_studio/calendar_studio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where the web store keeps image bytes (IndexedDB in the browser).
abstract interface class StudioAssetBytes {
  Future<Uint8List?> read(String id);
  Future<void> write(String id, Uint8List bytes);
  Future<void> delete(String id);
}

/// Studio images on web: a small manifest in preferences, the bytes in
/// [StudioAssetBytes], the same split as the native store's files.
///
/// Preferences are localStorage on web, about 5 MB for the whole site, so
/// bytes must not live there: one phone photo used to fill it and every
/// later image import failed.
class WebCalendarStudioAssetStore implements CalendarStudioAssetStore {
  WebCalendarStudioAssetStore(this._preferences, this._bytes);

  static const manifestKey = 'calendar_studio.assets.web.v2';

  /// Earlier releases kept base64 bytes here; moved out on first use.
  static const legacyKey = 'calendar_studio.assets.web.v1';

  final SharedPreferences _preferences;
  final StudioAssetBytes _bytes;
  Future<void>? _migration;

  Future<void> _ensureMigrated() => _migration ??= _migrateLegacy();

  Future<void> _migrateLegacy() async {
    final raw = _preferences.getString(legacyKey);
    if (raw == null) return;
    final legacy = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    final manifest = _manifest();
    for (final MapEntry(key: id, :value) in legacy.entries) {
      if (value is! Map || value['bytes'] is! String) continue;
      await _bytes.write(id, base64Decode(value['bytes'] as String));
      manifest[id] = {
        'name': value['name'],
        'width': value['width'],
        'height': value['height'],
      };
    }
    await _saveManifest(manifest);
    await _preferences.remove(legacyKey);
  }

  Map<String, dynamic> _manifest() {
    final raw = _preferences.getString(manifestKey);
    return raw == null ? {} : Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> _saveManifest(Map<String, dynamic> value) =>
      _preferences.setString(manifestKey, jsonEncode(value));

  @override
  Future<CalendarStudioAsset> importAsset(
    CalendarStudioAssetInput input,
  ) async {
    await _ensureMigrated();
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    await _bytes.write(id, Uint8List.fromList(input.bytes));
    final manifest = _manifest();
    manifest[id] = {
      'name': input.name,
      'width': input.width,
      'height': input.height,
    };
    await _saveManifest(manifest);
    return CalendarStudioAsset(
      id: id,
      name: input.name,
      width: input.width,
      height: input.height,
    );
  }

  @override
  Future<CalendarStudioAsset?> load(String assetId) async {
    await _ensureMigrated();
    final value = _manifest()[assetId];
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
    await _ensureMigrated();
    if (_manifest()[assetId] is! Map) return null;
    return _bytes.read(assetId);
  }

  @override
  Future<void> deleteUnusedAssets(Set<String> usedAssetIds) async {
    await _ensureMigrated();
    final manifest = _manifest();
    final unused = manifest.keys.where((id) => !usedAssetIds.contains(id));
    for (final id in unused.toList()) {
      await _bytes.delete(id);
      manifest.remove(id);
    }
    await _saveManifest(manifest);
  }
}
