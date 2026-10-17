import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tokens compare by value so the theme is only rebuilt on change', () {
    final a = CalendarStudioTokens.light.copyWith(
      primary: const Color(0xFF2F5BEA),
    );
    final b = CalendarStudioTokens.light.copyWith(
      primary: const Color(0xFF2F5BEA),
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a == CalendarStudioTokens.light, isFalse);
  });

  test('Clear chrome: centred titles, iOS transitions, flat cards', () {
    final clear = CalendarStudioTheme.fromTokens(
      CalendarStudioTokens.light,
      chrome: CalendarStudioChrome.clear,
      fontFamily: 'Inter',
      fontFamilyFallback: const ['Padauk'],
    );
    expect(clear.appBarTheme.centerTitle, isTrue);
    expect(
      clear.pageTransitionsTheme.builders[TargetPlatform.android],
      isA<CupertinoPageTransitionsBuilder>(),
    );
    final card = clear.cardTheme.shape! as RoundedRectangleBorder;
    expect(card.side, BorderSide.none);
    expect(clear.textTheme.bodyMedium?.fontFamily, 'Inter');
    expect(clear.chipTheme.labelStyle?.fontFamily, 'Inter');

    final material = CalendarStudioTheme.fromTokens(CalendarStudioTokens.light);
    expect(material.appBarTheme.centerTitle, isFalse);
    expect(
      (material.cardTheme.shape! as RoundedRectangleBorder).side,
      isNot(BorderSide.none),
    );
  });

  test('withLook keeps the services and changes only the look', () {
    final base = CalendarStudioConfiguration(projects: _Store());
    final look = base.withLook(
      chrome: CalendarStudioChrome.clear,
      appearance: CalendarStudioAppearance.dark,
      fontFamily: 'Inter',
    );
    expect(identical(look.projects, base.projects), isTrue);
    expect(look.chrome, CalendarStudioChrome.clear);
    expect(look.appearance, CalendarStudioAppearance.dark);
    expect(look.fontFamily, 'Inter');
    expect(base.chrome, CalendarStudioChrome.material);
  });
}

class _Store implements CalendarStudioProjectStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
