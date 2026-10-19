import 'dart:convert';
import 'dart:io';

import 'package:calendar_studio/calendar_studio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

CalendarStudioAssetStore createCalendarStudioAssetStore(
  SharedPreferences preferences,
) => _NativeStudioAssetStore(preferences);

class _NativeStudioAssetStore implements CalendarStudioAssetStore {
  _NativeStudioAssetStore(this._preferences);
  static const _manifestKey = 'calendar_studio.assets.v1';
  final SharedPreferences _preferences;

  Map<String, dynamic> _manifest() {
    final raw = _preferences.getString(_manifestKey);
    return raw == null ? {} : Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> _saveManifest(Map<String, dynamic> value) =>
      _preferences.setString(_manifestKey, jsonEncode(value));

  Future<Directory> _directory() async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory(p.join(root.path, 'calendar_studio', 'assets'));
    await directory.create(recursive: true);
    return directory;
  }

  @override
  Future<CalendarStudioAsset> importAsset(
    CalendarStudioAssetInput input,
  ) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final extension = p.extension(input.name).isEmpty
        ? '.bin'
        : p.extension(input.name);
    final path = p.join((await _directory()).path, '$id$extension');
    await File(path).writeAsBytes(input.bytes, flush: true);
    final manifest = _manifest();
    manifest[id] = {
      'name': input.name,
      'path': path,
      'width': input.width,
      'height': input.height,
    };
    await _saveManifest(manifest);
    return CalendarStudioAsset(
      id: id,
      name: input.name,
      width: input.width,
      height: input.height,
      localPath: path,
    );
  }

  @override
  Future<CalendarStudioAsset?> load(String assetId) async {
    final value = _manifest()[assetId];
    if (value is! Map) return null;
    return CalendarStudioAsset(
      id: assetId,
      name: value['name'] as String,
      width: value['width'] as int? ?? 0,
      height: value['height'] as int? ?? 0,
      localPath: value['path'] as String?,
    );
  }

  @override
  Future<List<int>?> loadBytes(String assetId) async {
    final asset = await load(assetId);
    if (asset?.localPath == null) return null;
    final file = File(asset!.localPath!);
    return file.existsSync() ? file.readAsBytes() : null;
  }

  @override
  Future<void> deleteUnusedAssets(Set<String> usedAssetIds) async {
    final manifest = _manifest();
    for (final id in manifest.keys.toList()) {
      if (usedAssetIds.contains(id)) continue;
      final value = manifest[id];
      final path = value is Map ? value['path'] as String? : null;
      if (path != null) {
        final file = File(path);
        if (file.existsSync()) await file.delete();
      }
      manifest.remove(id);
    }
    await _saveManifest(manifest);
  }
}
