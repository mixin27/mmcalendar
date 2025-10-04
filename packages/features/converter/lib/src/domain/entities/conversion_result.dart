import 'package:equatable/equatable.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';

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
