import 'package:equatable/equatable.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

class MoonPhaseResult extends Equatable {
  final CompleteDate dateFound;
  final int moonPhase; // 0=waxing, 1=full, 2=waning, 3=new
  final String moonPhaseName;
  final int daysFromStart;

  const MoonPhaseResult({
    required this.dateFound,
    required this.moonPhase,
    required this.moonPhaseName,
    required this.daysFromStart,
  });

  @override
  List<Object?> get props => [
    dateFound,
    moonPhase,
    moonPhaseName,
    daysFromStart,
  ];
}
