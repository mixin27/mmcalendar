import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/holiday_search.dart';

/// What the Holidays page is showing: a year, a filter and a search.
class HolidaysState {
  const HolidaysState({
    required this.year,
    this.query = '',
    this.filter = HolidayFilter.all,
    this.allYears = false,
  });

  final int year;
  final String query;
  final HolidayFilter filter;

  /// Whether search covers every year instead of [year].
  final bool allYears;

  bool get searching => query.trim().isNotEmpty;

  HolidaysState copyWith({
    int? year,
    String? query,
    HolidayFilter? filter,
    bool? allYears,
  }) => HolidaysState(
    year: year ?? this.year,
    query: query ?? this.query,
    filter: filter ?? this.filter,
    allYears: allYears ?? this.allYears,
  );
}

class HolidaysCubit extends Cubit<HolidaysState> {
  HolidaysCubit({int? year})
    : super(HolidaysState(year: year ?? DateTime.now().year));

  void showYear(int year) => emit(state.copyWith(year: year));

  void search(String query) => emit(
    state.copyWith(
      query: query,
      allYears: query.trim().isEmpty ? false : state.allYears,
    ),
  );

  void filterBy(HolidayFilter filter) => emit(state.copyWith(filter: filter));

  void searchAllYears() => emit(state.copyWith(allYears: true));
}
