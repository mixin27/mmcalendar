import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_localizations/shared_localizations.dart';

void main() {
  test('interface sentences use the app language digits throughout', () {
    final my = lookupAppLocalizations(const Locale('my'));
    final en = lookupAppLocalizations(const Locale('en'));
    expect(my.calendarDaysShort(2), '၂ ရက်');
    expect(my.calendarInDays(8), contains('၈'));
    expect(en.calendarDaysShort(2), '2 d');
    expect(en.calendarInDays(8), 'in 8 days');
  });

  testWidgets('uiNumber follows the app locale without grouping', (
    tester,
  ) async {
    final seen = <String>[];
    for (final locale in const [Locale('my'), Locale('en')]) {
      await tester.pumpWidget(
        Localizations(
          locale: locale,
          delegates: AppLocalizations.localizationsDelegates,
          child: Builder(
            builder: (context) {
              seen.add(context.uiNumber(2027));
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
    }
    expect(seen, ['၂၀၂၇', '2027']);
  });
}
