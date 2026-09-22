import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preflight blocks a required image without an asset', () {
    final now = DateTime(2026);
    final project = CalendarStudioProject(
      id: '1',
      name: 'test',
      templateId: 'blank',
      source: const CalendarStudioSource(year: 2027),
      createdAt: now,
      updatedAt: now,
      pages: const [
        CalendarStudioPage(
          id: 'p',
          label: 'January',
          year: 2027,
          month: 1,
          canvas: StudioCanvas(width: 210, height: 297),
          blocks: [
            CalendarStudioBlock(
              id: 'image',
              type: CalendarStudioBlockType.image,
              name: 'Image',
              bounds: StudioRect(left: .1, top: .1, width: .5, height: .5),
            ),
          ],
        ),
      ],
    );
    expect(
      CalendarStudioPreflight.check(
        project,
      ).any((issue) => issue.severity == CalendarStudioIssueSeverity.error),
      isTrue,
    );
  });
}
