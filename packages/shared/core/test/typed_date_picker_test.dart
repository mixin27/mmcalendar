import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  test('typed dates use the search parser', () {
    expect(parseTypedDate('Tabaung full moon 1388'), DateTime(2027, 3, 22));
    expect(parseTypedDate('13/4/2027'), DateTime(2027, 4, 13));
    expect(parseTypedDate('hello'), isNull);
  });

  testWidgets('the app picker takes a typed Myanmar date', (tester) async {
    tester.view
      ..physicalSize = const Size(420, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    DateTime? picked;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppMyanmarCalendarScope(
          language: Language.english,
          clearStyle: false,
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => picked = await showAppMyanmarDatePicker(
                context: context,
                initialDate: DateTime(2026, 11, 6),
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('mm-typed-date')),
      'Tabaung full moon 1388',
    );
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(picked, DateTime(2027, 3, 22));
  });
}
