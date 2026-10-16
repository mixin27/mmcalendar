import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mmcalendar/config/legacy_cleanup.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('removes calendar generation data once and keeps the rest', () async {
    SharedPreferences.setMockInitialValues({
      'calendar_generation_settings': '{"mode":"month"}',
      'calendar_generation_templates': '[]',
      'theme_mode': 'dark',
    });
    final preferences = await SharedPreferences.getInstance();
    final temp = await Directory.systemTemp.createTemp('legacy-cleanup');
    addTearDown(() => temp.delete(recursive: true));
    final images = Directory('${temp.path}/mmcalendar_background_images');
    await File('${images.path}/bg_1.png').create(recursive: true);

    await removeCalendarGenerationData(preferences, tempRoot: temp);

    expect(preferences.containsKey('calendar_generation_settings'), isFalse);
    expect(preferences.containsKey('calendar_generation_templates'), isFalse);
    expect(preferences.getString('theme_mode'), 'dark');
    expect(images.existsSync(), isFalse);

    // A second run is a no-op even if the key reappears.
    await preferences.setString('calendar_generation_settings', 'x');
    await removeCalendarGenerationData(preferences, tempRoot: temp);
    expect(preferences.getString('calendar_generation_settings'), 'x');
  });
}
