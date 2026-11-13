import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:myanmar_calendar_wear/features/day_details/models/day_details.dart';

part 'day_details_event.dart';
part 'day_details_state.dart';

class DayDetailsBloc extends Bloc<DayDetailsEvent, DayDetailsState> {
  DayDetailsBloc({
    Language language = Language.myanmar,
    DateTime Function()? now,
  }) : _language = language,
       _now = now ?? DateTime.now,
       super(const DayDetailsInitial()) {
    on<LoadToday>(
      (event, emit) => _load(emit, () => DayDetails(_now(), _language)),
    );
    on<NavigateToPreviousDay>(
      (event, emit) => _move(emit, (day) => day.previousDay),
    );
    on<NavigateToNextDay>((event, emit) => _move(emit, (day) => day.nextDay));
    on<LoadSpecificDate>(
      (event, emit) => _load(emit, () => DayDetails(event.date, _language)),
    );
    on<ChangeLanguage>((event, emit) {
      _language = event.language;
      _move(emit, (day) => day.inLanguage(_language));
    });
  }

  Language _language;
  final DateTime Function() _now;

  Language get language => _language;

  /// Today by this bloc's clock.
  DateTime get today => _now();

  void _load(Emitter<DayDetailsState> emit, DayDetails Function() load) {
    try {
      emit(DayDetailsLoaded(load()));
    } on Exception catch (e) {
      emit(DayDetailsError('$e'));
    }
  }

  void _move(
    Emitter<DayDetailsState> emit,
    DayDetails Function(DayDetails day) move,
  ) {
    final current = state;
    if (current is DayDetailsLoaded) {
      _load(emit, () => move(current.dayDetails));
    }
  }
}
