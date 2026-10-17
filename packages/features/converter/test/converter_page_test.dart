import 'package:converter/converter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

class _Analytics implements AnalyticsPort {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

Future<void> _pump(WidgetTester tester, AppStyle style) async {
  final getIt = GetIt.instance;
  await getIt.reset();
  getIt.registerSingleton<AnalyticsPort>(_Analytics());
  final repository = ConverterRepositoryImpl();
  final bloc = ConverterBloc(
    convertWesternToMyanmar: ConvertWesternToMyanmar(repository),
    convertMyanmarToWestern: ConvertMyanmarToWestern(repository),
    calculateDateDifference: CalculateDateDifference(repository),
    addSubtractDates: AddSubtractDates(repository),
    findNextMoonPhase: FindNextMoonPhase(repository),
  );
  addTearDown(bloc.close);
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(390, 1800);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.build(
        style: style,
        colorScheme: AppColorSchemes.modernLight,
      ),
      home: BlocProvider.value(value: bloc, child: const ConverterPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final style in [AppStyle.clear, AppStyle.material]) {
    group('${style.name} style', () {
      testWidgets('converts today straight away, with Copy and Share', (
        tester,
      ) async {
        String? copied;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              copied = (call.arguments as Map)['text'] as String;
            }
            return null;
          },
        );
        await _pump(tester, style);
        expect(find.text('Weekday'), findsOneWidget);
        expect(find.text('Copy'), findsOneWidget);
        expect(find.text('Share'), findsOneWidget);

        await tester.tap(find.text('Copy'));
        await tester.pump();
        expect(copied, contains('Weekday:'));
      });

      testWidgets('Myanmar to Western checks the input inline', (tester) async {
        await _pump(tester, style);
        await tester.tap(find.text('Myanmar → Western'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Convert').last);
        await tester.pumpAndSettle();
        expect(
          find.text('Enter a Myanmar year, month and day.'),
          findsOneWidget,
        );

        final fields = find.byType(TextField);
        await tester.enterText(fields.at(0), '1388');
        await tester.enterText(fields.at(1), '7');
        await tester.enterText(fields.at(2), '15');
        await tester.tap(find.text('Convert').last);
        await tester.pumpAndSettle();
        // Thadingyut full moon 1388 is 26 October 2026.
        expect(find.textContaining('October 26, 2026'), findsWidgets);
      });

      testWidgets('each tool keeps its own result', (tester) async {
        await _pump(tester, style);
        await tester.tap(find.text('Difference'));
        await tester.pumpAndSettle();
        expect(find.text('Swap dates'), findsOneWidget);
        expect(find.text('30'), findsOneWidget);

        await tester.tap(find.text('Moon'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Next '), findsOneWidget);

        await tester.tap(find.text('Converter').last);
        await tester.pumpAndSettle();
        expect(find.text('Weekday'), findsOneWidget);
      });
    });
  }

  tearDown(() => GetIt.instance.reset());
}
