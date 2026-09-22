import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'PDF exporter writes one valid document from the Studio scene',
    () async {
      final project = CalendarStudioTemplates.byId('jade-wall').create(
        id: 'pdf-project',
        source: const CalendarStudioSource(
          year: 2027,
          period: CalendarStudioPeriod.month,
        ),
        now: DateTime(2027),
      );
      final bytes = await const CalendarStudioPdfExporter(
        dataProvider: MyanmarCalendarStudioDataProvider(),
      ).export(project);

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    },
  );
}
