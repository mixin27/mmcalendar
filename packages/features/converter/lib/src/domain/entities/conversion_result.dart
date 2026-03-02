import 'package:equatable/equatable.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

class ConversionResult extends Equatable {
  final CompleteDate completeDate;
  final String formattedMyanmar;
  final String formattedWestern;

  const ConversionResult({
    required this.completeDate,
    required this.formattedMyanmar,
    required this.formattedWestern,
  });

  @override
  List<Object?> get props => [completeDate, formattedMyanmar, formattedWestern];
}
