import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' as material_ui;
import 'package:mmcalendar/config/calendar_studio_image_editor.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

Future<Uint8List> _png() async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    const Rect.fromLTWH(0, 0, 64, 32),
    Paint()..color = const Color(0xFF0E6B5C),
  );
  final image = await recorder.endRecording().toImage(64, 32);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

void main() {
  testWidgets('Studio image editor opens inside the app MaterialApp', (
    tester,
  ) async {
    final bytes = (await tester.runAsync(_png))!;
    late BuildContext hostContext;
    await tester.pumpWidget(
      MaterialApp(
        // Mirrors app.dart: SDK delegates plus material_ui's.
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          ...material_ui.GlobalMaterialLocalizations.delegates,
        ],
        home: Builder(
          builder: (context) {
            hostContext = context;
            return const Scaffold();
          },
        ),
      ),
    );

    const AppCalendarStudioImageEditor().edit(
      hostContext,
      original: bytes,
      maxDimension: 5000,
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    // A pushed route is built offstage on its first frame.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(ProImageEditor), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
