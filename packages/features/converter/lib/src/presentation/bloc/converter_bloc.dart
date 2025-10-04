import 'package:bloc/bloc.dart';

import '../../domain/usecases/add_subtract_dates.dart';
import '../../domain/usecases/calculate_date_difference.dart';
import '../../domain/usecases/convert_myanmar_to_western.dart';
import '../../domain/usecases/convert_western_to_myanmar.dart';
import '../../domain/usecases/find_next_moon_phase.dart';
import 'converter_event.dart';
import 'converter_state.dart';

class ConverterBloc extends Bloc<ConverterEvent, ConverterState> {
  final ConvertWesternToMyanmar convertWesternToMyanmar;
  final ConvertMyanmarToWestern convertMyanmarToWestern;
  final CalculateDateDifference calculateDateDifference;
  final AddSubtractDates addSubtractDates;
  final FindNextMoonPhase findNextMoonPhase;

  ConverterBloc({
    required this.convertWesternToMyanmar,
    required this.convertMyanmarToWestern,
    required this.calculateDateDifference,
    required this.addSubtractDates,
    required this.findNextMoonPhase,
  }) : super(ConverterInitial()) {
    on<ConvertWesternToMyanmarEvent>(_onConvertWesternToMyanmar);
    on<ConvertMyanmarToWesternEvent>(_onConvertMyanmarToWestern);
    on<CalculateDateDifferenceEvent>(_onCalculateDateDifference);
    on<PerformDateArithmeticEvent>(_onPerformDateArithmetic);
    on<FindNextMoonPhaseEvent>(_onFindNextMoonPhase);
    on<ResetConverterEvent>(_onResetConverter);
    on<ResetCalculatorEvent>(_onResetCalculator);
    on<ResetArithmeticEvent>(_onResetArithmetic);
    on<ResetMoonPhaseEvent>(_onResetMoonPhase);
  }

  void _onConvertWesternToMyanmar(
    ConvertWesternToMyanmarEvent event,
    Emitter<ConverterState> emit,
  ) {
    emit(ConversionLoading());

    final result = convertWesternToMyanmar(event.date);

    result.fold(
      (failure) => emit(ConversionError(failure.message)),
      (conversionResult) => emit(ConversionSuccess(conversionResult)),
    );
  }

  void _onConvertMyanmarToWestern(
    ConvertMyanmarToWesternEvent event,
    Emitter<ConverterState> emit,
  ) {
    emit(ConversionLoading());

    final result = convertMyanmarToWestern(event.year, event.month, event.day);

    result.fold(
      (failure) => emit(ConversionError(failure.message)),
      (conversionResult) => emit(ConversionSuccess(conversionResult)),
    );
  }

  void _onCalculateDateDifference(
    CalculateDateDifferenceEvent event,
    Emitter<ConverterState> emit,
  ) {
    emit(CalculationLoading());

    final result = calculateDateDifference(event.startDate, event.endDate);

    result.fold(
      (failure) => emit(CalculationError(failure.message)),
      (calculationResult) => emit(CalculationSuccess(calculationResult)),
    );
  }

  void _onPerformDateArithmetic(
    PerformDateArithmeticEvent event,
    Emitter<ConverterState> emit,
  ) {
    emit(ArithmeticLoading());

    final result = addSubtractDates(
      event.startDate,
      event.operation,
      event.value,
      event.unit,
    );

    result.fold(
      (failure) => emit(ArithmeticError(failure.message)),
      (arithmeticResult) => emit(ArithmeticSuccess(arithmeticResult)),
    );
  }

  void _onFindNextMoonPhase(
    FindNextMoonPhaseEvent event,
    Emitter<ConverterState> emit,
  ) {
    emit(MoonPhaseLoading());

    final result = findNextMoonPhase(event.startDate, event.moonPhase);

    result.fold(
      (failure) => emit(MoonPhaseError(failure.message)),
      (moonPhaseResult) => emit(MoonPhaseSuccess(moonPhaseResult)),
    );
  }

  void _onResetConverter(
    ResetConverterEvent event,
    Emitter<ConverterState> emit,
  ) {
    emit(ConverterInitial());
  }

  void _onResetCalculator(
    ResetCalculatorEvent event,
    Emitter<ConverterState> emit,
  ) {
    emit(ConverterInitial());
  }

  void _onResetArithmetic(
    ResetArithmeticEvent event,
    Emitter<ConverterState> emit,
  ) {
    emit(ConverterInitial());
  }

  void _onResetMoonPhase(
    ResetMoonPhaseEvent event,
    Emitter<ConverterState> emit,
  ) {
    emit(ConverterInitial());
  }
}
