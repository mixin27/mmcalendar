import 'package:alchemist/alchemist.dart';
import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _gallery(Size size) => SizedBox.fromSize(
  size: size,
  child: CalendarStudioWorkspace(
    configuration: CalendarStudioConfiguration(projects: _Store()),
  ),
);

Future<void> _openGallery(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(find.text('Browse presets'));
  await tester.pumpAndSettle();
}

void main() {
  goldenTest(
    'preset gallery on a phone',
    fileName: 'gallery_phone',
    pumpBeforeTest: _openGallery,
    builder: () => _gallery(const Size(390, 800)),
  );

  goldenTest(
    'preset detail sheet',
    fileName: 'gallery_detail',
    pumpBeforeTest: (tester) async {
      await _openGallery(tester);
      await tester.tap(
        find.byKey(const ValueKey('calendar-studio-preset-family')),
      );
      await tester.pumpAndSettle();
    },
    builder: () => _gallery(const Size(390, 800)),
  );

  goldenTest(
    'preset gallery on desktop',
    fileName: 'gallery_desktop',
    pumpBeforeTest: (tester) async {
      await _openGallery(tester);
      await tester.tap(
        find.byKey(const ValueKey('calendar-studio-preset-festival')),
      );
      await tester.pumpAndSettle();
    },
    builder: () => _gallery(const Size(1280, 800)),
  );
}

class _Store implements CalendarStudioProjectStore {
  @override
  Future<void> delete(String id) async {}
  @override
  Future<List<CalendarStudioProject>> list() async => const [];
  @override
  Future<CalendarStudioProject?> load(String id) async => null;
  @override
  Future<void> save(CalendarStudioProject project) async {}
}
