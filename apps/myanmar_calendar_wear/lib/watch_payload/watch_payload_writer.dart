import 'dart:convert';

import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_widget_payload/shared_widget_payload.dart';

/// Writes the slim payload the Tile and complications draw.
///
/// It is [WidgetPayloadBuilder.buildSlim] (`days`, `s`, `upcoming`) as
/// JSON under [key]. SharedPreferences keeps it in the native
/// `FlutterSharedPreferences` file as `flutter.watch_payload`, where
/// `WatchPayload.kt` reads it and asks the Tile and complications to
/// refresh when it changes.
class WatchPayloadWriter {
  const WatchPayloadWriter(this._preferences);

  static const key = 'watch_payload';

  final SharedPreferences _preferences;

  Future<Map<String, Object?>> write(Language language, {DateTime? now}) async {
    final today = now ?? DateTime.now();
    final payload = WidgetPayloadBuilder.buildSlim(
      today: today,
      language: language,
      generatedAt: today,
    );
    await _preferences.setString(key, jsonEncode(payload));
    return payload;
  }

  /// The payload last written, if any.
  Map<String, Object?>? read() {
    final json = _preferences.getString(key);
    return json == null ? null : jsonDecode(json) as Map<String, Object?>;
  }
}
