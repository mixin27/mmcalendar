import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

/// Calendar generation was replaced by Calendar Studio. Its saved designs
/// referenced temporary files that are usually gone, so they are removed
/// rather than migrated. Runs once; exported PDFs and images are untouched.
Future<void> removeCalendarGenerationData(
  SharedPreferences preferences, {
  Directory? tempRoot,
}) async {
  const done = 'legacy.calendar_generation_removed.v1';
  if (preferences.getBool(done) ?? false) return;
  // Former StorageKeys.calendarGenerationSettings / calendarGenerationTemplates.
  await preferences.remove('calendar_generation_settings');
  await preferences.remove('calendar_generation_templates');
  if (!kIsWeb) {
    try {
      final images = Directory(
        p.join(
          (tempRoot ?? Directory.systemTemp).path,
          'mmcalendar_background_images',
        ),
      );
      if (await images.exists()) await images.delete(recursive: true);
    } catch (_) {
      // Temporary files; the OS clears them eventually.
    }
  }
  await preferences.setBool(done, true);
}
