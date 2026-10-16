import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('studio font licences load from the bundled assets', () async {
    CalendarStudioFontCatalog.registerLicenses();
    final packages = <String>{};
    await for (final entry in LicenseRegistry.licenses) {
      packages.addAll(entry.packages);
    }
    for (final font in CalendarStudioFontCatalog.fonts) {
      expect(packages, contains('Calendar Studio · ${font.family}'));
    }
  });
}
