import 'dart:typed_data';

import 'package:alchemist/alchemist.dart';
import 'package:calendar_studio/calendar_studio.dart';
import 'package:calendar_studio/src/presentation/calendar_studio_export_flow.dart';
import 'package:flutter/material.dart';

void main() {
  StudioExportRun run() {
    final project = CalendarStudioTemplates.byId('family').create(
      id: 'golden-flow',
      source: const CalendarStudioSource(year: 2027),
      now: DateTime(2027),
    );
    return StudioExportRun(
      project: project,
      pages: project.pages,
      preset: CalendarStudioExportPreset.a4Pdf,
      destination: CalendarStudioExportDestination.save,
    );
  }

  Widget frame(StudioExportRun value) => Theme(
    data: CalendarStudioTheme.fromTokens(
      CalendarStudioTokens.light,
      brightness: Brightness.light,
    ),
    child: MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: SizedBox(
        width: 420,
        child: StudioExportFlow(
          run: value,
          onCancel: () {},
          onDeliver: (_) async {},
        ),
      ),
    ),
  );

  goldenTest(
    'export flow: rendering and done',
    fileName: 'export_flow',
    builder: () => GoldenTestGroup(
      columns: 2,
      children: [
        GoldenTestScenario(name: 'rendering', child: frame(run()..progress(4))),
        GoldenTestScenario(
          name: 'done',
          child: frame(
            run()
              ..delivering(
                CalendarStudioExportArtifact(
                  name: 'family-calendar-2027.pdf',
                  mimeType: 'application/pdf',
                  bytes: Uint8List(14 << 20),
                ),
              )
              ..done(CalendarStudioExportDestination.save),
          ),
        ),
      ],
    ),
  );
}
