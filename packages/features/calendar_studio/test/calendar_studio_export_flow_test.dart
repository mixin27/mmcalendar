import 'dart:typed_data';

import 'package:calendar_studio/calendar_studio.dart';
import 'package:calendar_studio/src/presentation/calendar_studio_export_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

StudioExportRun _run({
  CalendarStudioExportDestination destination =
      CalendarStudioExportDestination.save,
}) {
  final project = CalendarStudioTemplates.byId('family').create(
    id: 'flow',
    source: const CalendarStudioSource(year: 2027),
    now: DateTime(2027),
  );
  return StudioExportRun(
    project: project,
    pages: project.pages.take(4).toList(),
    preset: CalendarStudioExportPreset.a4Pdf,
    destination: destination,
  );
}

Widget _host(
  StudioExportRun run, {
  List<CalendarStudioExportDestination>? log,
}) => MaterialApp(
  theme: CalendarStudioTheme.fromTokens(
    CalendarStudioTokens.light,
    brightness: Brightness.light,
  ),
  home: MediaQuery(
    data: const MediaQueryData(disableAnimations: true),
    child: StudioExportFlow(
      run: run,
      onCancel: () {},
      onDeliver: (destination) async {
        log?.add(destination);
        run.done(destination);
      },
    ),
  ),
);

void main() {
  testWidgets('rendering shows the page in progress and filled cells', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final run = _run()..progress(2);
    await tester.pumpWidget(_host(run));
    expect(find.text('of 4 pages'), findsOneWidget);
    expect(find.textContaining('Rendering March'), findsOneWidget);
    expect(find.bySemanticsLabel('January rendered'), findsOneWidget);
    expect(find.bySemanticsLabel('March rendering'), findsOneWidget);
    expect(find.bySemanticsLabel('April waiting'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Cancel'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('done offers the actions not yet taken', (tester) async {
    final log = <CalendarStudioExportDestination>[];
    final run = _run()
      ..delivering(
        CalendarStudioExportArtifact(
          name: 'family-2027.pdf',
          mimeType: 'application/pdf',
          bytes: Uint8List(300 * 1024),
        ),
      )
      ..done(CalendarStudioExportDestination.save);
    await tester.pumpWidget(_host(run, log: log));
    expect(find.text('Exported 4 pages'), findsOneWidget);
    expect(find.text('family-2027.pdf'), findsOneWidget);
    expect(find.text('PDF · 4 pages · 0.3 MB'), findsOneWidget);

    final save = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text('Save'),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );
    expect(save.onPressed, isNull);
    await tester.tap(find.text('Share'));
    await tester.pump();
    expect(log, [CalendarStudioExportDestination.share]);
    expect(find.text('Print'), findsOneWidget);
  });
}
