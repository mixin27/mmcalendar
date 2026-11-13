import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:myanmar_calendar_wear/features/day_details/bloc/day_details_bloc.dart';
import 'package:myanmar_calendar_wear/features/day_details/models/day_details.dart';

void main() {
  final today = DateTime(2025, 10, 6, 21, 30);
  DayDetailsBloc build() =>
      DayDetailsBloc(language: Language.english, now: () => today);
  DayDetailsLoaded loaded(int day, [Language language = Language.english]) =>
      DayDetailsLoaded(DayDetails(DateTime(2025, 10, day), language));

  blocTest<DayDetailsBloc, DayDetailsState>(
    'loads today without the time of day',
    build: build,
    act: (bloc) => bloc.add(const LoadToday()),
    expect: () => [loaded(6)],
  );

  blocTest<DayDetailsBloc, DayDetailsState>(
    'moves a day at a time and back to today',
    build: build,
    act: (bloc) => bloc
      ..add(const LoadToday())
      ..add(const NavigateToNextDay())
      ..add(const NavigateToNextDay())
      ..add(const NavigateToPreviousDay())
      ..add(const LoadToday()),
    expect: () => [loaded(6), loaded(7), loaded(8), loaded(7), loaded(6)],
  );

  blocTest<DayDetailsBloc, DayDetailsState>(
    'crosses months',
    build: build,
    act: (bloc) => bloc
      ..add(LoadSpecificDate(DateTime(2025, 10, 31)))
      ..add(const NavigateToNextDay()),
    expect: () => [
      loaded(31),
      DayDetailsLoaded(DayDetails(DateTime(2025, 11), Language.english)),
    ],
  );

  blocTest<DayDetailsBloc, DayDetailsState>(
    'ignores navigation before a day is loaded',
    build: build,
    act: (bloc) => bloc.add(const NavigateToNextDay()),
    expect: () => <DayDetailsState>[],
  );

  blocTest<DayDetailsBloc, DayDetailsState>(
    'keeps the day when the language changes',
    build: build,
    act: (bloc) => bloc
      ..add(LoadSpecificDate(DateTime(2025, 10, 8)))
      ..add(const ChangeLanguage(Language.myanmar))
      ..add(const NavigateToNextDay()),
    expect: () => [
      loaded(8),
      loaded(8, Language.myanmar),
      loaded(9, Language.myanmar),
    ],
    verify: (bloc) => expect(bloc.language, Language.myanmar),
  );
}
