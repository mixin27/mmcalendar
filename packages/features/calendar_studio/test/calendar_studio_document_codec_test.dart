import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('project document survives a versioned JSON round trip', () {
    final now = DateTime(2027, 1, 1);
    final project = CalendarStudioTemplates.byId('jade-wall').create(
      id: 'project-1',
      source: const CalendarStudioSource(year: 2027),
      now: now,
    );
    final result = CalendarStudioDocumentCodec.decode(
      CalendarStudioDocumentCodec.encode(project),
    );
    expect(result, project);
  });

  test('year project assigns the correct month and year to every page', () {
    final project = CalendarStudioTemplates.byId('jade-wall').create(
      id: 'project-2',
      source: const CalendarStudioSource(year: 2027, month: 11),
      now: DateTime(2027),
    );

    expect((project.pages[0].year, project.pages[0].month), (2027, 11));
    expect((project.pages[2].year, project.pages[2].month), (2028, 1));
    expect((project.pages[11].year, project.pages[11].month), (2028, 10));
  });
}
