import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:myanmar_calendar_wear/watch_payload/watch_payload_writer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_widget_payload/shared_widget_payload.dart';

void main() {
  final now = DateTime(2025, 10, 6, 9);
  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  test('writes the shared builder slim payload as JSON', () async {
    await WatchPayloadWriter(preferences).write(Language.english, now: now);
    final json = preferences.getString(WatchPayloadWriter.key);
    expect(json, isNotNull);
    expect(
      jsonDecode(json!),
      jsonDecode(
        jsonEncode(
          WidgetPayloadBuilder.buildSlim(
            today: now,
            language: Language.english,
            generatedAt: now,
          ),
        ),
      ),
    );
  });

  test('has what the Tile and complications read', () async {
    final payload = await WatchPayloadWriter(
      preferences,
    ).write(Language.english, now: now);
    expect(payload.keys, containsAll(['start', 's', 'days', 'upcoming']));
    expect(payload['start'], '2025-10-06');

    final today = (payload['days']! as List).first as Map;
    expect(today['d'], '2025-10-06');
    expect(today['ph'], 1, reason: 'full moon');
    expect(today['sab'], 1);
    expect(today['il'], isA<double>());
    expect(today['my'], isNotEmpty);

    final s = payload['s']! as Map;
    expect(s['moonPhases'], hasLength(4));
    expect(s['weekdays'], hasLength(7));

    final next = (payload['upcoming']! as List).cast<Map>().firstWhere(
      (u) => u['k'] == 'holiday' || u['k'] == 'sabbath',
    );
    expect(next['d'], '2025-10-06');
    expect(next['n'], isNotEmpty);
  });

  test('follows the calendar language', () async {
    final writer = WatchPayloadWriter(preferences);
    await writer.write(Language.myanmar, now: now);
    expect(writer.read()?['lang'], 'my');
    final s = writer.read()!['s']! as Map;
    expect(s['today'], 'ယနေ့');

    await writer.write(Language.english, now: now);
    expect(writer.read()?['lang'], 'en');
  });

  test('is small enough to read on every Tile refresh', () async {
    await WatchPayloadWriter(preferences).write(Language.myanmar, now: now);
    final bytes = utf8.encode(preferences.getString('watch_payload')!).length;
    expect(bytes, lessThan(64 * 1024));
  });

  test('reads nothing before the first write', () {
    expect(WatchPayloadWriter(preferences).read(), isNull);
  });
}
