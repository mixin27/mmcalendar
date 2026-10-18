import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

Future<BuildContext> _pump(WidgetTester tester, AppStyle style) async {
  late BuildContext context;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.build(
        style: style,
        colorScheme: AppColorSchemes.modernLight,
      ),
      home: Scaffold(
        body: Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  return context;
}

void main() {
  for (final style in [AppStyle.clear, AppStyle.material]) {
    group(style.name, () {
      testWidgets('prompt returns the trimmed text', (tester) async {
        final context = await _pump(tester, style);
        final result = showAppPrompt(
          context: context,
          title: 'Rename',
          initial: 'Old',
          confirmLabel: 'Save',
        );
        await tester.pumpAndSettle();
        expect(
          find.byType(
            style == AppStyle.clear ? CupertinoAlertDialog : AlertDialog,
          ),
          findsOneWidget,
        );
        await tester.enterText(
          find.byType(style == AppStyle.clear ? CupertinoTextField : TextField),
          '  New name ',
        );
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(await result, 'New name');
      });

      testWidgets('prompt returns null when cancelled', (tester) async {
        final context = await _pump(tester, style);
        final result = showAppPrompt(
          context: context,
          title: 'Rename',
          confirmLabel: 'Save',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(await result, isNull);
      });

      testWidgets('action sheet runs the chosen action', (tester) async {
        final context = await _pump(tester, style);
        String? picked;
        final done = showAppActionSheet(
          context: context,
          title: 'Choose image',
          actions: [
            AppMenuAction(label: 'Camera', onSelected: () => picked = 'c'),
            AppMenuAction(label: 'Files', onSelected: () => picked = 'f'),
          ],
        );
        await tester.pumpAndSettle();
        if (style == AppStyle.clear) {
          expect(find.byType(CupertinoActionSheet), findsOneWidget);
        }
        await tester.tap(find.text('Files'));
        await tester.pumpAndSettle();
        await done;
        expect(picked, 'f');
      });
    });
  }
}
