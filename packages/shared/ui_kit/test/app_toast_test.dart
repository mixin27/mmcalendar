import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

Widget _app({
  bool screenReader = false,
  required void Function(BuildContext) onTap,
}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(accessibleNavigation: screenReader),
    child: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => onTap(context),
            child: const Text('go'),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('a toast with an action counts down and dismisses itself', (
    tester,
  ) async {
    var undone = 0;
    await tester.pumpWidget(
      _app(
        onTap: (context) => context.showToast(
          'Block deleted',
          actionLabel: 'Undo',
          onAction: () => undone++,
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));
    expect(find.text('Block deleted'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('2'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Block deleted'), findsNothing);
    expect(undone, 0);
  });

  testWidgets('the action runs and closes the toast before the timer', (
    tester,
  ) async {
    var undone = 0;
    await tester.pumpWidget(
      _app(
        onTap: (context) => context.showToast(
          'Block deleted',
          actionLabel: 'Undo',
          onAction: () => undone++,
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(undone, 1);
    expect(find.text('Block deleted'), findsNothing);
  });

  testWidgets('a new toast replaces the current one', (tester) async {
    var count = 0;
    await tester.pumpWidget(
      _app(onTap: (context) => context.showToast('Message ${++count}')),
    );
    await tester.tap(find.text('go'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('Message 1'), findsNothing);
    expect(find.text('Message 2'), findsOneWidget);
  });

  testWidgets('with a screen reader on, the toast stays until dismissed', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        screenReader: true,
        onTap: (context) =>
            context.showToast('Saved', actionLabel: 'Undo', onAction: () {}),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Saved'), findsOneWidget);
  });

  testWidgets('errors use the longer duration and old helpers still work', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(onTap: (context) => context.showErrorSnackBar('Sync failed')),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('6'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.text('Sync failed'), findsNothing);
  });
}
